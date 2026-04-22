import { jest } from '@jest/globals'

const supabaseMock = {
  auth: {
    getUser: jest.fn()
  },
  from: jest.fn()
}

jest.unstable_mockModule('../../../src/config/supabase.js', () => ({
  supabase: supabaseMock
}))

const { requireAuth } = await import('../../../src/shared/middleware/auth.js')

describe('requireAuth middleware', () => {
  let req
  let res
  let next

  beforeEach(() => {
    jest.clearAllMocks()
    req = { headers: {} }
    res = {
      status: jest.fn(() => res),
      json: jest.fn()
    }
    next = jest.fn()
  })

  test('returns 401 if authorization header missing', async () => {
    await requireAuth(req, res, next)

    expect(res.status).toHaveBeenCalledWith(401)
    expect(next).not.toHaveBeenCalled()
  })

  test('returns 401 for invalid token', async () => {
    req.headers.authorization = 'Bearer bad-token'
    supabaseMock.auth.getUser.mockResolvedValueOnce({ data: { user: null }, error: { message: 'bad' } })

    await requireAuth(req, res, next)

    expect(res.status).toHaveBeenCalledWith(401)
    expect(next).not.toHaveBeenCalled()
  })

  test('attaches req.user and calls next for valid token', async () => {
    req.headers.authorization = 'Bearer valid-token'
    supabaseMock.auth.getUser.mockResolvedValueOnce({
      data: { user: { id: 'user-1' } },
      error: null
    })

    const userQuery = {
      select: jest.fn(() => userQuery),
      eq: jest.fn(() => userQuery),
      single: jest.fn(async () => ({ data: { id: 'user-1', user_type: 'creator' }, error: null }))
    }

    supabaseMock.from.mockReturnValueOnce(userQuery)

    await requireAuth(req, res, next)

    expect(req.user).toEqual({ id: 'user-1', user_type: 'creator' })
    expect(next).toHaveBeenCalled()
  })
})
