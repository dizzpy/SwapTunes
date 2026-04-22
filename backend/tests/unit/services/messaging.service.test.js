import { jest } from '@jest/globals'
import { makeQueryBuilder } from '../../helpers/supabase-mock.js'

const supabaseMock = {
  from: jest.fn(),
  rpc: jest.fn(async () => ({ data: [], error: null }))
}

const createNotificationMock = jest.fn(async () => ({}))

jest.unstable_mockModule('../../../src/config/supabase.js', () => ({
  supabase: supabaseMock
}))

jest.unstable_mockModule('../../../src/features/notifications/notifications.service.js', () => ({
  notificationsService: {
    createNotification: createNotificationMock
  }
}))

const messagingService = await import('../../../src/features/messaging/conversations.service.js')

describe('messaging service', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  test('getConversations uses single RPC call', async () => {
    supabaseMock.rpc.mockResolvedValueOnce({ data: [{ id: 'c1' }], error: null })

    const result = await messagingService.getConversations('user-1')

    expect(supabaseMock.rpc).toHaveBeenCalledWith('get_conversations_for_user', {
      p_user_id: 'user-1'
    })
    expect(result).toEqual([{ id: 'c1' }])
  })

  test('getMessages throws 403 for non-participant', async () => {
    const convoQuery = makeQueryBuilder({
      result: {
        data: { id: 'conv-1', user_one_id: 'a', user_two_id: 'b' },
        error: null
      }
    })
    supabaseMock.from.mockReturnValue(convoQuery)

    await expect(messagingService.getMessages('user-1', 'conv-1', {})).rejects.toMatchObject({
      statusCode: 403
    })
  })

  test('sendMessage rejects empty content', async () => {
    await expect(messagingService.sendMessage('user-1', 'conv-1', '   ')).rejects.toMatchObject({
      statusCode: 400
    })
  })

  test('markMessagesRead updates messages for participant', async () => {
    const convoQuery = makeQueryBuilder({
      result: {
        data: { id: 'conv-1', user_one_id: 'user-1', user_two_id: 'u2' },
        error: null
      }
    })
    const messagesQuery = makeQueryBuilder({ result: { data: null, error: null } })

    supabaseMock.from.mockImplementation((table) => {
      if (table === 'conversations') return convoQuery
      if (table === 'messages') return messagesQuery
      return makeQueryBuilder()
    })

    const result = await messagingService.markMessagesRead('user-1', 'conv-1')

    expect(result).toEqual({ success: true })
    expect(messagesQuery.match).toHaveBeenCalledWith({ conversation_id: 'conv-1' })
    expect(messagesQuery.neq).toHaveBeenCalledWith('sender_id', 'user-1')
  })

  test('deleteConversation soft deletes and returns success', async () => {
    const convoSelect = makeQueryBuilder({
      result: {
        data: { id: 'conv-1', user_one_id: 'user-1', user_two_id: 'u2' },
        error: null
      }
    })
    const convoUpdate = makeQueryBuilder({
      result: {
        data: { deleted_by_user_one: true, deleted_by_user_two: false },
        error: null
      }
    })

    let conversationsCalls = 0
    supabaseMock.from.mockImplementation((table) => {
      if (table === 'conversations') {
        conversationsCalls += 1
        return conversationsCalls === 1 ? convoSelect : convoUpdate
      }
      return makeQueryBuilder()
    })

    const result = await messagingService.deleteConversation('user-1', 'conv-1')

    expect(result).toEqual({ success: true })
  })
})
