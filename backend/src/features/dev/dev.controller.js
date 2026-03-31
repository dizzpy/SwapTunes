import * as devService from './dev.service.js'
import { success } from '../../shared/utils/response.js'

export const resetRole = async (req, res, next) => {
  try {
    const { username, role, clear_creator_profile } = req.body
    if (!username || !role) {
      return res.status(400).json({ error: { code: 'INVALID', message: 'username and role are required' } })
    }
    if (role !== 'listener' && role !== 'creator') {
      return res.status(400).json({ error: { code: 'INVALID', message: "role must be 'listener' or 'creator'" } })
    }
    const result = await devService.resetUserRole(username, role, clear_creator_profile === true)
    success(res, result)
  } catch (err) {
    next(err)
  }
}
