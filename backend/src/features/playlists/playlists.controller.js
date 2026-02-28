import * as playlistsService from './playlists.service.js'
import { success } from '../../shared/utils/response.js'

// Get available playlists controller handler.
export const getAvailablePlaylists = async (req, res, next) => {
  try {
    const playlists = await playlistsService.getAvailableSpotifyPlaylists(req.user)
    success(res, playlists)
  } catch (err) {
    next(err)
  }
}

// Import playlists controller handler.
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

// Get user playlists controller handler.
export const getUserPlaylists = async (req, res, next) => {
  try {
    const playlists = await playlistsService.getUserPlaylists(req.params.userId)
    success(res, playlists)
  } catch (err) {
    next(err)
  }
}

// Delete playlist controller handler.
export const deletePlaylist = async (req, res, next) => {
  try {
    const result = await playlistsService.deletePlaylist(req.user.id, req.params.playlistId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}
