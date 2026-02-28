import * as authService from '../services/auth.service.js'
import { success, fail } from '../utils/response.js'
import { supabase } from '../config/supabase.js'

export const getMe = async (req, res, next) => {
  try {
    success(res, req.user)
  } catch (err) {
    next(err)
  }
}

export const setupProfile = async (req, res, next) => {
  try {
    // auth middleware guarantees req.user from supabase Auth, but maybe not in public.users yet
    // wait, auth middleware currently requires it to be in public.users.
    // So for setup, we need a special auth middleware that just verifies JWT but doesn't check public.users
    // I'll adjust the logic in routes to handle this.

    // assuming req.authData contains raw supabase user id
    const userId = req.authData.user.id
    const user = await authService.setupProfile(userId, req.validatedBody)
    success(res, user, 201)
  } catch (err) {
    next(err)
  }
}

export const connectSpotify = async (req, res, next) => {
  try {
    const { code, redirect_uri } = req.validatedBody
    const user = await authService.connectSpotify(req.user.id, code, redirect_uri)
    success(res, user)
  } catch (err) {
    next(err)
  }
}
