import * as creatorService from './creator.service.js'
import { success } from '../../shared/utils/response.js'

// Setup creator controller handler.
export const setupCreator = async (req, res, next) => {
  try {
    const profile = await creatorService.setupCreatorProfile(req.user.id, req.validatedBody)
    success(res, profile, 201)
  } catch (err) {
    next(err)
  }
}

// Update creator profile controller handler.
export const updateCreatorProfile = async (req, res, next) => {
  try {
    const profile = await creatorService.updateCreatorProfile(req.user.id, req.body)
    success(res, profile)
  } catch (err) {
    next(err)
  }
}

// Deactivate creator — switch back to listener mode.
export const deactivateCreator = async (req, res, next) => {
  try {
    await creatorService.deactivateCreator(req.user.id)
    success(res, { message: 'Switched to listener mode' })
  } catch (err) {
    next(err)
  }
}
