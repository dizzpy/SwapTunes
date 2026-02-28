import * as playlistsService from '../services/playlists.service.js'
import { success } from '../utils/response.js'

export const getAvailablePlaylists = async (req, res, next) => {
  try {
    const playlists = await playlistsService.getAvailableSpotifyPlaylists(req.user)
    success(res, playlists)
  } catch (err) {
    next(err)
  }
}

export const importPlaylists = async (req, res, next) => {
  try {
    const { playlist_ids } = req.body
    if (!playlist_ids || !Array.isArray(playlist_ids)) {
      throw { statusCode: 400, code: 'VALIDATION_FAILED', message: 'playlist_ids array is required' }
    }
    const result = await playlistsService.importPlaylists(req.user, playlist_ids)
    success(res, result, 201)
  } catch (err) {
    next(err)
  }
}
