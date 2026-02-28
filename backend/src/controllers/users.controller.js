import * as usersService from '../services/users.service.js'
import { success } from '../utils/response.js'

export const getProfile = async (req, res, next) => {
  try {
    const profile = await usersService.getProfile(req.params.username)
    success(res, profile)
  } catch (err) {
    next(err)
  }
}

export const followUser = async (req, res, next) => {
  try {
    const { userId } = req.params
    const result = await usersService.followUser(req.user.id, userId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

export const unfollowUser = async (req, res, next) => {
  try {
    const { userId } = req.params
    const result = await usersService.unfollowUser(req.user.id, userId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}
