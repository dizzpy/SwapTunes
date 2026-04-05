import * as discoverService from './discover.service.js'
import { success } from '../../shared/utils/response.js'

// Get genres controller handler.
export const getGenres = async (req, res, next) => {
  try {
    const genres = await discoverService.getGenres()
    success(res, genres)
  } catch (err) {
    next(err)
  }
}

// Discover playlists controller handler.
export const discoverPlaylists = async (req, res, next) => {
  try {
    const playlists = await discoverService.getDiscoverPlaylists(req.query)
    success(res, playlists)
  } catch (err) {
    next(err)
  }
}

// Suggested users controller handler.
export const suggestedUsers = async (req, res, next) => {
  try {
    const limit = parseInt(req.query.limit) || 20
    const users = await discoverService.getSuggestedUsers(req.user.id, limit)
    success(res, users)
  } catch (err) {
    next(err)
  }
}

// Trending genres controller handler.
export const trendingGenres = async (req, res, next) => {
  try {
    const limit = parseInt(req.query.limit) || 10
    const genres = await discoverService.getTrendingGenres(limit)
    success(res, genres)
  } catch (err) {
    next(err)
  }
}

// Search controller handler.
export const search = async (req, res, next) => {
  try {
    const { q, type } = req.query
    if (!q) throw { statusCode: 400, code: 'VALIDATION_FAILED', message: 'Search query "q" is required' }

    const results = await discoverService.search(q, type || 'all', req.query)
    success(res, results)
  } catch (err) {
    next(err)
  }
}
