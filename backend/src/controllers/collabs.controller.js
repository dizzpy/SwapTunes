import * as collabsService from '../services/collabs.service.js'
import { success } from '../utils/response.js'

export const createCollab = async (req, res, next) => {
  try {
    const collab = await collabsService.createCollab(req.user.id, req.validatedBody)
    success(res, collab, 201)
  } catch (err) {
    next(err)
  }
}

export const getCollabs = async (req, res, next) => {
  try {
    const collabs = await collabsService.getCollabs(req.query)
    success(res, collabs)
  } catch (err) {
    next(err)
  }
}

export const getCollabById = async (req, res, next) => {
  try {
    const collab = await collabsService.getCollabById(req.params.collabId)
    success(res, collab)
  } catch (err) {
    next(err)
  }
}

export const updateCollab = async (req, res, next) => {
  try {
    const collab = await collabsService.updateCollab(req.user.id, req.params.collabId, req.body) // Note: needs validation
    success(res, collab)
  } catch (err) {
    next(err)
  }
}

export const deleteCollab = async (req, res, next) => {
  try {
    const result = await collabsService.deleteCollab(req.user.id, req.params.collabId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

export const getMyCollabs = async (req, res, next) => {
  try {
    const collabs = await collabsService.getMyCollabs(req.user.id, req.query)
    success(res, collabs)
  } catch (err) {
    next(err)
  }
}
