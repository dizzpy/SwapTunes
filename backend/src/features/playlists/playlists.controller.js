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

// Get single playlist controller handler.
export const getPlaylist = async (req, res, next) => {
  try {
    const playlist = await playlistsService.getPlaylistById(req.params.playlistId)
    success(res, playlist)
  } catch (err) {
    next(err)
  }
}

// Create manual playlist controller handler.
export const createPlaylist = async (req, res, next) => {
  try {
    const { name } = req.body
    if (!name || !String(name).trim()) {
      throw { statusCode: 400, code: 'VALIDATION_FAILED', message: 'name is required' }
    }
    const result = await playlistsService.createPlaylist(req.user.id, req.body)
    success(res, result, 201)
  } catch (err) {
    next(err)
  }
}

// Update playlist controller handler.
export const updatePlaylist = async (req, res, next) => {
  try {
    const result = await playlistsService.updatePlaylist(req.user.id, req.params.playlistId, req.body)
    success(res, result)
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

// Like playlist controller handler.
export const likePlaylist = async (req, res, next) => {
  try {
    const result = await playlistsService.likePlaylist(req.user.id, req.params.playlistId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

// Unlike playlist controller handler.
export const unlikePlaylist = async (req, res, next) => {
  try {
    const result = await playlistsService.unlikePlaylist(req.user.id, req.params.playlistId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}
