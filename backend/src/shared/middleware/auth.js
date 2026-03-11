import { supabase } from '../../config/supabase.js'

export const requireAuth = async (req, res, next) => {
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

    const { data: dbUser, error: dbError } = await supabase.from('users').select('*').eq('id', user.id).single()

    if (dbError || !dbUser) {
      return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'User not found' } })
    }

    req.user = dbUser
    next()
  } catch (error) {
    next(error)
  }
}
