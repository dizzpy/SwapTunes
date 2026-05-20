import * as collabsService from './collabs.service.js'
import { success } from '../../shared/utils/response.js'

// Create collab controller handler.
export const createCollab = async (req, res, next) => {
  try {
    const collab = await collabsService.createCollab(req.user.id, req.validatedBody)
    success(res, collab, 201)
  } catch (err) {
    next(err)
  }
}

// Get collabs controller handler.
export const getCollabs = async (req, res, next) => {
  try {
    const collabs = await collabsService.getCollabs(req.query)
    success(res, collabs)
  } catch (err) {
    next(err)
  }
}

// Get collab by id controller handler.
export const getCollabById = async (req, res, next) => {
  try {
    const collab = await collabsService.getCollabById(req.params.collabId)
    success(res, collab)
  } catch (err) {
    next(err)
  }
}

// Update collab controller handler.
export const updateCollab = async (req, res, next) => {
  try {
    const collab = await collabsService.updateCollab(req.user.id, req.params.collabId, req.body) // Note: needs validation
    success(res, collab)
  } catch (err) {
    next(err)
  }
}

// Delete collab controller handler.
export const deleteCollab = async (req, res, next) => {
  try {
    const result = await collabsService.deleteCollab(req.user.id, req.params.collabId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

// Get my collabs controller handler.
export const getMyCollabs = async (req, res, next) => {
  try {
    const collabs = await collabsService.getMyCollabs(req.user.id, req.query)
    success(res, collabs)
  } catch (err) {
    next(err)
  }
}

// Get collabs by user id controller handler.
export const getUserCollabs = async (req, res, next) => {
  try {
    const collabs = await collabsService.getUserCollabs(req.params.userId, req.query)
    success(res, collabs)
  } catch (err) {
    next(err)
  }
}

// Get AI-matched creators for a collab listing controller handler.
export const getCollabMatches = async (req, res, next) => {
  try {
    const { collabId } = req.params
    const overrideKey = req.headers['x-gemini-key']
    const matches = await collabsService.findCollabMatches(collabId, req.user.id, overrideKey)
    success(res, matches)
  } catch (err) {
    next(err)
  }
}
