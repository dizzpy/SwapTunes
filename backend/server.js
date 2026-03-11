import app from './src/app.js'
import { logger } from './src/shared/utils/logger.js'

const PORT = process.env.PORT || 3000

const server = app.listen(PORT, () => {
  logger.info(`🚀 Server running on port ${PORT}`)
})

// Global unhandled error handlers
process.on('uncaughtException', (err) => {
  logger.fatal(err, 'UNCAUGHT EXCEPTION! 💥 Shutting down...')
  process.exit(1)
})

process.on('unhandledRejection', (err) => {
  logger.fatal(err, 'UNHANDLED REJECTION! 💥 Shutting down...')
  server.close(() => {
    process.exit(1)
  })
})

// shutdown on SIGTERM
process.on('SIGTERM', () => {
  logger.info('👋 SIGTERM RECEIVED. Shutting down gracefully')
  server.close(() => {
    logger.info('💥 Process terminated!')
  })
})
