import { jest } from '@jest/globals'

export const makeQueryBuilder = ({ result = { data: null, error: null } } = {}) => {
  const q = {
    select: jest.fn(() => q),
    insert: jest.fn(() => q),
    update: jest.fn(() => q),
    delete: jest.fn(() => q),
    upsert: jest.fn(() => q),
    eq: jest.fn(() => q),
    neq: jest.fn(() => q),
    lt: jest.fn(() => q),
    not: jest.fn(() => q),
    in: jest.fn(() => q),
    match: jest.fn(() => q),
    order: jest.fn(() => q),
    limit: jest.fn(() => q),
    range: jest.fn(() => q),
    single: jest.fn(async () => result),
    maybeSingle: jest.fn(async () => result),
    then: (resolve, reject) => Promise.resolve(result).then(resolve, reject)
  }

  return q
}
