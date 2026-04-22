import { jest } from '@jest/globals'
import { requireCreator } from '../../../src/shared/middleware/requireCreator.js'

describe('requireCreator middleware', () => {
  let req
  let res
  let next

  beforeEach(() => {
    req = { user: undefined }
    res = {
      status: jest.fn(() => res),
      json: jest.fn()
    }
    next = jest.fn()
  })

  test('calls next when user_type is creator', () => {
    req.user = { id: 'user-1', user_type: 'creator' }

    requireCreator(req, res, next)

    expect(next).toHaveBeenCalled()
  })

  test('returns 403 when user_type is listener', () => {
    req.user = { id: 'user-1', user_type: 'listener' }

    requireCreator(req, res, next)

    expect(res.status).toHaveBeenCalledWith(403)
    expect(next).not.toHaveBeenCalled()
  })

  test('returns 403 when req.user missing', () => {
    requireCreator(req, res, next)

    expect(res.status).toHaveBeenCalledWith(403)
    expect(next).not.toHaveBeenCalled()
  })
})
