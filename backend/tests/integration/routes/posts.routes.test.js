import { jest } from '@jest/globals'
import request from 'supertest'
import { createTestApp } from '../../helpers/test-app.js'
import { makeQueryBuilder } from '../../helpers/supabase-mock.js'

const supabaseMock = {
  auth: {
    getUser: jest.fn()
  },
  from: jest.fn(),
  rpc: jest.fn(async () => ({ error: null }))
}

jest.unstable_mockModule('../../../src/config/supabase.js', () => ({
  supabase: supabaseMock
}))

jest.unstable_mockModule('../../../src/features/notifications/notifications.service.js', () => ({
  notificationsService: {
    createNotification: jest.fn(async () => ({}))
  }
}))

const { default: postsRoutes } = await import('../../../src/features/posts/posts.routes.js')

const uuid = '00000000-0000-4000-8000-000000000001'

describe('posts routes', () => {
  const app = createTestApp(postsRoutes)

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
          single: jest.fn(async () => ({ data: { id: 'user-1', user_type: 'creator' }, error: null }))
        }
      }
      return makeQueryBuilder()
    })
  })

  test('POST / creates post with valid auth and body', async () => {
    const postQuery = makeQueryBuilder({
      result: {
        data: { id: 'post-1', content: 'hello' },
        error: null
      }
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
          single: jest.fn(async () => ({ data: { id: 'user-1', user_type: 'creator' }, error: null }))
        }
      }
      if (table === 'posts') return postQuery
      return makeQueryBuilder()
    })

    const res = await request(app).post('/api/v1/').set('Authorization', 'Bearer token').send({ content: 'hello post' })

    expect(res.status).toBe(201)
    expect(res.body.id).toBe('post-1')
  })

  test('POST / returns 401 without auth header', async () => {
    const res = await request(app).post('/api/v1/').send({ content: 'hello post' })

    expect(res.status).toBe(401)
  })

  test('POST / returns 400 on missing content', async () => {
    const res = await request(app).post('/api/v1/').set('Authorization', 'Bearer token').send({})

    expect(res.status).toBe(400)
  })

  test('GET /feed returns array with auth', async () => {
    const hiddenQuery = makeQueryBuilder({ result: { data: [], error: null } })
    const feedQuery = makeQueryBuilder({ result: { data: [], error: null } })

    supabaseMock.from.mockImplementation((table) => {
      if (table === 'users') {
        return {
          select: jest.fn(function () {
            return this
          }),
          eq: jest.fn(function () {
            return this
          }),
          single: jest.fn(async () => ({ data: { id: 'user-1', user_type: 'creator' }, error: null }))
        }
      }
      if (table === 'hidden_posts') return hiddenQuery
      if (table === 'posts') return feedQuery
      return makeQueryBuilder()
    })

    const res = await request(app).get('/api/v1/feed').set('Authorization', 'Bearer token')

    expect(res.status).toBe(200)
    expect(Array.isArray(res.body)).toBe(true)
  })

  test('POST /:postId/like returns 200 with valid UUID param', async () => {
    const likesQuery = makeQueryBuilder({ result: { data: [{ id: 'like-1' }], error: null } })
    const postOwnerQuery = makeQueryBuilder({ result: { data: { user_id: 'owner-1' }, error: null } })

    supabaseMock.from.mockImplementation((table) => {
      if (table === 'users') {
        return {
          select: jest.fn(function () {
            return this
          }),
          eq: jest.fn(function () {
            return this
          }),
          single: jest.fn(async () => ({ data: { id: 'user-1', user_type: 'creator' }, error: null }))
        }
      }
      if (table === 'post_likes') return likesQuery
      if (table === 'posts') return postOwnerQuery
      return makeQueryBuilder()
    })

    const res = await request(app).post(`/api/v1/${uuid}/like`).set('Authorization', 'Bearer token')

    expect(res.status).toBe(200)
  })

  test('POST /:postId/like returns 409 on duplicate-like conflict', async () => {
    const likesQuery = makeQueryBuilder({
      result: { data: null, error: { code: '23505', message: 'duplicate key value' } }
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
          single: jest.fn(async () => ({ data: { id: 'user-1', user_type: 'creator' }, error: null }))
        }
      }
      if (table === 'post_likes') return likesQuery
      return makeQueryBuilder()
    })

    const res = await request(app).post(`/api/v1/${uuid}/like`).set('Authorization', 'Bearer token')

    expect(res.status).toBe(409)
    expect(res.body.error.code).toBe('ALREADY_LIKED')
  })

  test('POST /:postId/comments returns 201 with valid payload', async () => {
    const commentsQuery = makeQueryBuilder({ result: { data: { id: 'c1' }, error: null } })
    const postOwnerQuery = makeQueryBuilder({ result: { data: { user_id: 'owner-1' }, error: null } })

    supabaseMock.from.mockImplementation((table) => {
      if (table === 'users') {
        return {
          select: jest.fn(function () {
            return this
          }),
          eq: jest.fn(function () {
            return this
          }),
          single: jest.fn(async () => ({ data: { id: 'user-1', user_type: 'creator' }, error: null }))
        }
      }
      if (table === 'comments') return commentsQuery
      if (table === 'posts') return postOwnerQuery
      return makeQueryBuilder()
    })

    const res = await request(app)
      .post(`/api/v1/${uuid}/comments`)
      .set('Authorization', 'Bearer token')
      .send({ content: 'hello' })

    expect(res.status).toBe(201)
    expect(res.body.id).toBe('c1')
  })
})
