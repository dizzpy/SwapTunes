import express from 'express'
import { errorHandler } from '../../src/shared/middleware/errorHandler.js'

export const createTestApp = (router, prefix = '/api/v1') => {
  const app = express()
  app.use(express.json())
  app.use(prefix, router)
  app.use(errorHandler)
  return app
}
