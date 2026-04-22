import { jest } from '@jest/globals'
import { makeQueryBuilder } from '../../helpers/supabase-mock.js'

const supabaseMock = {
  from: jest.fn(),
  rpc: jest.fn(async () => ({ error: null }))
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

const postsService = await import('../../../src/features/posts/posts.service.js')

describe('posts.service', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  test('createPost creates and returns post', async () => {
    const created = { id: 'post-1', content: 'hello' }
    const postsQuery = makeQueryBuilder({ result: { data: created, error: null } })
    supabaseMock.from.mockReturnValue(postsQuery)

    const result = await postsService.createPost('user-1', { content: 'hello' })

    expect(supabaseMock.from).toHaveBeenCalledWith('posts')
    expect(result).toEqual(created)
  })

  test('getFeed maps is_liked and excludes hidden ids', async () => {
    const hiddenQuery = makeQueryBuilder({ result: { data: [{ post_id: 'post-9' }], error: null } })
    const posts = [
      { id: 'post-1', post_likes: [{ user_id: 'user-1' }] },
      { id: 'post-2', post_likes: [{ user_id: 'user-2' }] }
    ]
    const feedQuery = makeQueryBuilder({ result: { data: posts, error: null } })

    supabaseMock.from.mockImplementation((table) => {
      if (table === 'hidden_posts') return hiddenQuery
      if (table === 'posts') return feedQuery
      return makeQueryBuilder()
    })

    const result = await postsService.getFeed('user-1', { page: 1, limit: 20 })

    expect(result[0].is_liked).toBe(true)
    expect(result[1].is_liked).toBe(false)
    expect(feedQuery.not).toHaveBeenCalled()
  })

  test('likePost does not increment when duplicate upsert returns no row', async () => {
    const likesQuery = makeQueryBuilder({ result: { data: [], error: null } })
    supabaseMock.from.mockImplementation((table) => {
      if (table === 'post_likes') return likesQuery
      return makeQueryBuilder()
    })

    const result = await postsService.likePost('user-1', 'post-1')

    expect(result).toEqual({ success: true })
    expect(supabaseMock.rpc).not.toHaveBeenCalled()
    expect(createNotificationMock).not.toHaveBeenCalled()
  })

  test('addComment inserts and triggers increment rpc', async () => {
    const commentsQuery = makeQueryBuilder({ result: { data: { id: 'c1' }, error: null } })
    const postOwnerQuery = makeQueryBuilder({ result: { data: { user_id: 'owner-1' }, error: null } })

    supabaseMock.from.mockImplementation((table) => {
      if (table === 'comments') return commentsQuery
      if (table === 'posts') return postOwnerQuery
      return makeQueryBuilder()
    })

    const result = await postsService.addComment('user-1', 'post-1', 'nice')

    expect(result).toEqual({ id: 'c1' })
    expect(supabaseMock.rpc).toHaveBeenCalledWith('increment_comments', { p_id: 'post-1' })
    expect(createNotificationMock).toHaveBeenCalled()
  })

  test('reportPost throws on db error', async () => {
    const reportsQuery = makeQueryBuilder({
      result: { data: null, error: { message: 'failed' } }
    })
    supabaseMock.from.mockReturnValue(reportsQuery)

    await expect(postsService.reportPost('user-1', 'post-1', 'spam')).rejects.toMatchObject({
      code: 'REPORT_FAILED'
    })
  })
})
