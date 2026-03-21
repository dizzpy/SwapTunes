import * as usersService from './users.service.js'
import { success } from '../../shared/utils/response.js'

// Get profile controller handler.
export const getProfile = async (req, res, next) => {
  try {
    const profile = await usersService.getProfile(req.params.username, req.user.id)
    success(res, profile)
  } catch (err) {
    next(err)
  }
}

// Follow user controller handler.
export const followUser = async (req, res, next) => {
  try {
    const { userId } = req.params
    const result = await usersService.followUser(req.user.id, userId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

// Unfollow user controller handler.
export const unfollowUser = async (req, res, next) => {
  try {
    const { userId } = req.params
    const result = await usersService.unfollowUser(req.user.id, userId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

// Update profile controller handler.
export const updateProfile = async (req, res, next) => {
  try {
    const result = await usersService.updateProfile(req.user.id, req.body)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

// Get followers controller handler.
export const getFollowers = async (req, res, next) => {
  try {
    const { userId } = req.params
    const data = await usersService.getFollowers(userId, req.query)
    success(res, data)
  } catch (err) {
    next(err)
  }
}

// Get following controller handler.
export const getFollowing = async (req, res, next) => {
  try {
    const { userId } = req.params
    const data = await usersService.getFollowing(userId, req.query)
    success(res, data)
  } catch (err) {
    next(err)
  }
}
