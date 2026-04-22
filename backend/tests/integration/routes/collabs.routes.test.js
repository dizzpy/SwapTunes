import { jest } from '@jest/globals'
import request from 'supertest'
import { createTestApp } from '../../helpers/test-app.js'
import { makeQueryBuilder } from '../../helpers/supabase-mock.js'

const supabaseMock = {
  auth: {
    getUser: jest.fn()
  },
  from: jest.fn(),
  rpc: jest.fn()
}

const matchCreatorsForCollabMock = jest.fn()

jest.unstable_mockModule('../../../src/config/supabase.js', () => ({
  supabase: supabaseMock
}))

jest.unstable_mockModule('../../../src/shared/services/ai.service.js', () => ({
  buildSongPlan: jest.fn(),
  matchCreatorsForCollab: matchCreatorsForCollabMock
}))

const { default: collabsRoutes } = await import('../../../src/features/collabs/collabs.routes.js')

const collabId = '00000000-0000-4000-8000-000000000001'

describe('collabs AI-match routes', () => {
  const app = createTestApp(collabsRoutes)

  beforeEach(() => {
    jest.clearAllMocks()

    supabaseMock.auth.getUser.mockResolvedValue({
      data: { user: { id: 'user-1' } },
      error: null
    })

    matchCreatorsForCollabMock.mockResolvedValue({
      matches: [{ userId: 'user-2', matchScore: 92, reason: 'great fit' }]
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

      if (table === 'collaborations') {
        return makeQueryBuilder({
          result: {
            data: {
              id: collabId,
              creator_id: 'user-1',
              title: 'Need vocalist',
              description: 'Rock collab',
              looking_for: ['vocalist'],
              genre_style: ['rock']
            },
            error: null
          }
        })
      }

      if (table === 'creator_profiles') {
        return makeQueryBuilder({
          result: {
            data: [
              {
                user_id: 'user-2',
                role_title: 'Singer',
                specializations: ['vocalist'],
                users: { username: 'singer', avatar_url: null, user_type: 'creator' }
              }
            ],
            error: null
          }
        })
      }

      return makeQueryBuilder()
    })
  })

  test('POST /:collabId/match returns 200 with AI matches for creator owner', async () => {
    const res = await request(app).post(`/api/v1/${collabId}/match`).set('Authorization', 'Bearer token')

    expect(res.status).toBe(200)
    expect(Array.isArray(res.body)).toBe(true)
    expect(res.body[0].userId).toBe('user-2')
    expect(res.body[0].matchScore).toBe(92)
  })

  test('POST /:collabId/match returns 403 for listener role', async () => {
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
      return makeQueryBuilder()
    })

    const res = await request(app).post(`/api/v1/${collabId}/match`).set('Authorization', 'Bearer token')

    expect(res.status).toBe(403)
  })

  test('POST /:collabId/match returns 403 when creator does not own collab', async () => {
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

      if (table === 'collaborations') {
        return makeQueryBuilder({
          result: {
            data: {
              id: collabId,
              creator_id: 'other-user',
              title: 'Need vocalist',
              description: 'Rock collab',
              looking_for: ['vocalist'],
              genre_style: ['rock']
            },
            error: null
          }
        })
      }

      return makeQueryBuilder()
    })

    const res = await request(app).post(`/api/v1/${collabId}/match`).set('Authorization', 'Bearer token')

    expect(res.status).toBe(403)
    expect(res.body.error.code).toBe('FORBIDDEN')
  })
})
