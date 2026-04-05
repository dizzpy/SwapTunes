import { Router } from 'express'
import * as playlistsController from './playlists.controller.js'
import { requireAuth } from '../../shared/middleware/auth.js'
import { requireSpotify } from '../../shared/middleware/requireSpotify.js'

const router = Router()

// Spotify-specific routes (require Spotify to be connected)
router.get('/spotify/available', requireAuth, requireSpotify, playlistsController.getAvailablePlaylists)
router.post('/import', requireAuth, requireSpotify, playlistsController.importPlaylists)

// Manual playlist creation
router.post('/create', requireAuth, playlistsController.createPlaylist)

// User playlists (public)
router.get('/user/:userId', playlistsController.getUserPlaylists)

// Single playlist (public read)
router.get('/:playlistId', playlistsController.getPlaylist)

// Update & delete (auth required, ownership checked in service)
router.patch('/:playlistId', requireAuth, playlistsController.updatePlaylist)
router.delete('/:playlistId', requireAuth, playlistsController.deletePlaylist)

// Likes
router.post('/:playlistId/like', requireAuth, playlistsController.likePlaylist)
router.delete('/:playlistId/like', requireAuth, playlistsController.unlikePlaylist)

export default router
