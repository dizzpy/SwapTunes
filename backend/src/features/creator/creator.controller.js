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

// Build a song plan using AI.
export const songBuilder = async (req, res, next) => {
  try {
    const { idea, genre, lyrics, type } = req.validatedBody
    const result = await creatorService.buildSong({ idea, genre, lyrics, type })
    success(res, result)
  } catch (err) {
    next(err)
  }
}

// Save a song plan result to the database.
export const saveSongPlan = async (req, res, next) => {
  try {
    const { title, data } = req.validatedBody
    const saved = await creatorService.saveSongPlan(req.user.id, { title, data })
    success(res, saved, 201)
  } catch (err) {
    next(err)
  }
}
