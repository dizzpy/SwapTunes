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
