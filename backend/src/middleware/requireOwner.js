export const requireOwner = (resourceUserIdField = 'user_id') => {
  return (req, res, next) => {
    // This is a simplified owner check.
    // In a real scenario, you usually fetch the resource first, then check ownership.
    // We'll leave this generic for now, but typically it expects req.resource attached before this middleware.

    if (!req.resource) {
      return res
        .status(500)
        .json({ error: { code: 'SERVER_ERROR', message: 'Resource not loaded for ownership check' } })
    }

    if (req.resource[resourceUserIdField] !== req.user.id) {
      return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'You do not own this resource' } })
    }

    next()
  }
}
