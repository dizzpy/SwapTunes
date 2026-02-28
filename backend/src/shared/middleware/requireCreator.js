export const requireCreator = (req, res, next) => {
  if (req.user?.user_type !== 'creator') {
    return res.status(403).json({
      error: { code: 'FORBIDDEN', message: 'Creator account required.' }
    })
  }
  next()
}
