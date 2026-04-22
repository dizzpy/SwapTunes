import { jest } from '@jest/globals'
import request from 'supertest'
import { createTestApp } from '../../helpers/test-app.js'
import { makeQueryBuilder } from '../../helpers/supabase-mock.js'

const supabaseMock = {
  auth: {
    getUser: jest.fn()
  },
  from: jest.fn(),
  rpc: jest.fn(async () => ({ data: [], error: null }))
}

jest.unstable_mockModule('../../../src/config/supabase.js', () => ({
  supabase: supabaseMock
}))

jest.unstable_mockModule('../../../src/features/notifications/notifications.service.js', () => ({
  notificationsService: {
    createNotification: jest.fn(async () => ({}))
  }
}))

const { default: conversationsRoutes } = await import('../../../src/features/messaging/conversations.routes.js')

const conversationId = '00000000-0000-4000-8000-000000000001'

describe('messaging routes', () => {
  const app = createTestApp(conversationsRoutes)

  beforeEach(() => {
    jest.clearAllMocks()
    supabaseMock.auth.getUser.mockResolvedValue({
      data: { user: { id: 'user-1' } },
      error: null
    })

    supabaseMock.from.mockImplementation((table) => {
      if (table === 'users') {
        return {
          select: jest.fn(function () {
            return this
          }),
          eq: jest.fn(function () {
            return this
          }),
          single: jest.fn(async () => ({ data: { id: 'user-1', user_type: 'listener' }, error: null }))
        }
      }
      if (table === 'conversations') {
        return makeQueryBuilder({
          result: {
            data: {
              id: conversationId,
              user_one_id: 'user-1',
              user_two_id: 'user-2',
              deleted_by_user_one: false,
              deleted_by_user_two: false
            },
            error: null
          }
        })
      }
      if (table === 'messages') {
        return makeQueryBuilder({ result: { data: { id: 'm1' }, error: null } })
      }
      return makeQueryBuilder()
    })
  })

  test('GET / returns 200 with auth', async () => {
    supabaseMock.rpc.mockResolvedValueOnce({ data: [], error: null })

    const res = await request(app).get('/api/v1/').set('Authorization', 'Bearer token')

    expect(res.status).toBe(200)
    expect(Array.isArray(res.body)).toBe(true)
  })

  test('GET / returns 401 without auth', async () => {
    const res = await request(app).get('/api/v1/')

    expect(res.status).toBe(401)
  })

  test('POST /:id/messages returns 201 for participant with content', async () => {
    const res = await request(app)
      .post(`/api/v1/${conversationId}/messages`)
      .set('Authorization', 'Bearer token')
      .send({ content: 'hello' })

    expect(res.status).toBe(201)
    expect(res.body.id).toBe('m1')
  })

  test('POST /:id/messages returns 400 for empty content', async () => {
    const res = await request(app)
      .post(`/api/v1/${conversationId}/messages`)
      .set('Authorization', 'Bearer token')
      .send({ content: '   ' })

    expect(res.status).toBe(400)
  })

  test('PATCH /:id/read returns 200 for participant', async () => {
    const res = await request(app).patch(`/api/v1/${conversationId}/read`).set('Authorization', 'Bearer token')

    expect(res.status).toBe(200)
    expect(res.body.success).toBe(true)
  })

  test('POST /:id/messages returns 403 for non-participant', async () => {
    supabaseMock.from.mockImplementation((table) => {
      if (table === 'users') {
        return {
          select: jest.fn(function () {
            return this
          }),
          eq: jest.fn(function () {
            return this
          }),
          single: jest.fn(async () => ({ data: { id: 'user-1', user_type: 'listener' }, error: null }))
        }
      }
      if (table === 'conversations') {
        return makeQueryBuilder({
          result: {
            data: {
              id: conversationId,
              user_one_id: 'user-x',
              user_two_id: 'user-y'
            },
            error: null
          }
        })
      }
      return makeQueryBuilder()
    })

    const res = await request(app)
      .post(`/api/v1/${conversationId}/messages`)
      .set('Authorization', 'Bearer token')
      .send({ content: 'hello' })

    expect(res.status).toBe(403)
  })

  test('PATCH /:id/read returns 403 for non-participant', async () => {
    supabaseMock.from.mockImplementation((table) => {
      if (table === 'users') {
        return {
          select: jest.fn(function () {
            return this
          }),
          eq: jest.fn(function () {
            return this
          }),
          single: jest.fn(async () => ({ data: { id: 'user-1', user_type: 'listener' }, error: null }))
        }
      }
      if (table === 'conversations') {
        return makeQueryBuilder({
          result: {
            data: {
              id: conversationId,
              user_one_id: 'user-x',
              user_two_id: 'user-y'
            },
            error: null
          }
        })
      }
      return makeQueryBuilder()
    })

    const res = await request(app).patch(`/api/v1/${conversationId}/read`).set('Authorization', 'Bearer token')

    expect(res.status).toBe(403)
  })
})
