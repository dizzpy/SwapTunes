import * as authService from './auth.service.js'
import { success } from '../../shared/utils/response.js'

// Get me controller handler.
export const getMe = async (req, res, next) => {
  try {
    success(res, req.user)
  } catch (err) {
    next(err)
  }
}

// Setup profile controller handler.
export const setupProfile = async (req, res, next) => {
  try {
    const userId = req.authData.user.id
    const userEmail = req.authData.user.email
    const user = await authService.setupProfile(userId, userEmail, req.validatedBody)
    success(res, user, 201)
  } catch (err) {
    next(err)
  }
}

// Connect spotify controller handler.
export const connectSpotify = async (req, res, next) => {
  try {
    const { code, redirect_uri } = req.validatedBody
    const user = await authService.connectSpotify(req.user.id, code, redirect_uri)
    success(res, user)
  } catch (err) {
    next(err)
  }
}
