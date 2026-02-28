import * as creatorService from '../services/creator.service.js'
import { success } from '../utils/response.js'

export const setupCreator = async (req, res, next) => {
  try {
     const profile = await creatorService.setupCreatorProfile(req.user.id, req.validatedBody)
     success(res, profile, 201)
  } catch (err) {
     next(err)
  }
}
