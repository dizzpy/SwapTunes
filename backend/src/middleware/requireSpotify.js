export const requireSpotify = (req, res, next) => {
  if (!req.user?.spotify_connected) {
    return res.status(403).json({
      error: { code: 'FORBIDDEN', message: 'Spotify account connection required.' }
    })
  }
  next()
}
