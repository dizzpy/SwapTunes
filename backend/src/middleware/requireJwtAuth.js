import { supabase } from '../config/supabase.js'

export const requireJwtAuth = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split('Bearer ')[1]
    if (!token) {
      return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Missing token' } })
    }

    const {
      data: { user },
      error
    } = await supabase.auth.getUser(token)

    if (error || !user) {
      return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Invalid token' } })
    }

    req.authData = { user }
    next()
  } catch (error) {
    next(error)
  }
}
