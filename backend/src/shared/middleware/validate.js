export const validate = (schema) => {
  return (req, res, next) => {
    try {
      const parsed = schema.safeParse(req.body)

      if (!parsed.success) {
        return res.status(400).json({
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Invalid request data',
            details: parsed.error.format()
          }
        })
      }

      req.validatedBody = parsed.data
      next()
    } catch (error) {
      next(error)
    }
  }
}

export const validateParams = (schema) => {
  return (req, res, next) => {
    const parsed = schema.safeParse(req.params)

    if (!parsed.success) {
      return res.status(400).json({
        error: {
          code: 'INVALID_PARAMS',
          message: 'Invalid URL parameters',
          details: parsed.error.format()
        }
      })
    }

    next()
  }
}
