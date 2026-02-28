import { logger } from '../utils/logger.js'

export const errorHandler = (err, req, res, _next) => {
  let statusCode = err.statusCode || 500
  let code = err.code || 'INTERNAL_SERVER_ERROR'
  let message = err.message || 'An unexpected error occurred'
  const environment = process.env.NODE_ENV || 'development'

  // Log error (especially for 500s)
  if (statusCode === 500) {
    logger.error({ err, req: { method: req.method, url: req.url, body: req.body } }, 'Unhandled Exception')
  } else {
    logger.warn({ err, req: { method: req.method, url: req.url } }, 'Operational Error')
  }

  res.status(statusCode).json({
    error: {
      code,
      message,
      ...(environment === 'development' && { stack: err.stack })
    }
  })
}
