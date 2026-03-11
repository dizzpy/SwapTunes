import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import compression from 'compression'
import pinoHttp from 'pino-http'
import { globalLimiter } from './shared/middleware/rateLimiter.js'
import { logger } from './shared/utils/logger.js'

import { router } from './router.js'
import { errorHandler } from './shared/middleware/errorHandler.js'
import dotenv from 'dotenv'

// Initialize event listeners
import './shared/events/index.js'
import { initializeJobs } from './shared/jobs/index.js'

dotenv.config()

// Start background workers
initializeJobs()

const app = express()

app.use(helmet())
app.use(cors())
app.use(express.json())
app.use(compression()) // Compress all responses
app.use(pinoHttp({ logger })) // Log HTTP requests
app.use('/api/', globalLimiter) // Apply global rate limiter to all api routes

app.use('/api/v1', router)

// Global Error Handler
app.use(errorHandler)

export default app
