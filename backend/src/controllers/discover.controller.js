import * as discoverService from '../services/discover.service.js'
import { success } from '../utils/response.js'

export const discoverPlaylists = async (req, res, next) => {
  try {
     const playlists = await discoverService.getDiscoverPlaylists(req.query)
     success(res, playlists)
  } catch (err) { next(err) }
}

export const search = async (req, res, next) => {
  try {
     const { q, type } = req.query
     if (!q) throw { statusCode: 400, code: 'VALIDATION_FAILED', message: 'Search query "q" is required' }
     
     const results = await discoverService.search(q, type || 'all', req.query)
     success(res, results)
  } catch (err) { next(err) }
}
