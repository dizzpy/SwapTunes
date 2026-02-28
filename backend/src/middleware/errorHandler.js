export const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500
  const environment = process.env.NODE_ENV || 'development'

  res.status(statusCode).json({
    error: {
      code: err.code || 'INTERNAL_SERVER_ERROR',
      message: err.message || 'An unexpected error occurred',
      ...(environment === 'development' && { stack: err.stack })
    }
  })
}
