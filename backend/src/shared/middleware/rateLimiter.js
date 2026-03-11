import rateLimit from 'express-rate-limit'

// Limit requests globally
export const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 150, // Limit each IP to 150 requests per `window`
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  message: {
    error: {
      code: 'TOO_MANY_REQUESTS',
      message: 'Too many requests from this IP, please try again after 15 minutes.'
    }
  }
})

// Stricter limits for authentication routes
export const authLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10, // Limit each IP to 10 requests per 1 hour window
  message: {
    error: {
      code: 'TOO_MANY_REQUESTS',
      message: 'Too many auth attempts from this IP, please try again after 1 hour.'
    }
  }
})
