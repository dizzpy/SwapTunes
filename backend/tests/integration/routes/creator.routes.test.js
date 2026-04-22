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

const buildSongPlanMock = jest.fn()

jest.unstable_mockModule('../../../src/config/supabase.js', () => ({
  supabase: supabaseMock
}))

jest.unstable_mockModule('../../../src/shared/services/ai.service.js', () => ({
  buildSongPlan: buildSongPlanMock,
  matchCreatorsForCollab: jest.fn()
}))

const { default: creatorRoutes } = await import('../../../src/features/creator/creator.routes.js')

describe('creator routes', () => {
  const app = createTestApp(creatorRoutes)

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
          single: jest.fn(async () => ({ data: { id: 'user-1', user_type: 'creator' }, error: null })),
          update: jest.fn(function () {
            return this
          })
        }
      }
      if (table === 'saved_song_plans') {
        return makeQueryBuilder({ result: { data: { id: 'plan-1' }, error: null } })
      }
      if (table === 'creator_profiles') {
        return makeQueryBuilder({ result: { data: null, error: null } })
      }
      if (table === 'collaborations') {
        return makeQueryBuilder({ result: { data: null, error: null } })
      }
      return makeQueryBuilder()
    })
  })

  test('POST /song-builder returns 200 for creator with valid payload', async () => {
    buildSongPlanMock.mockResolvedValueOnce({ title: 'My song' })

    const res = await request(app)
      .post('/api/v1/song-builder')
      .set('Authorization', 'Bearer token')
      .send({ idea: 'Need a melodic hook', genre: 'Rock', type: 'vocal' })

    expect(res.status).toBe(200)
    expect(res.body.title).toBe('My song')
  })

  test('POST /song-builder returns 403 for listener', async () => {
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

    const res = await request(app)
      .post('/api/v1/song-builder')
      .set('Authorization', 'Bearer token')
      .send({ idea: 'Need a melodic hook', genre: 'Rock', type: 'vocal' })

    expect(res.status).toBe(403)
  })

  test('POST /song-builder returns 400 on invalid payload', async () => {
    const res = await request(app)
      .post('/api/v1/song-builder')
      .set('Authorization', 'Bearer token')
      .send({ idea: 'bad', genre: '' })

    expect(res.status).toBe(400)
  })
})
