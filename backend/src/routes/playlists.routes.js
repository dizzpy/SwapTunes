import { Router } from 'express'
import * as playlistsController from '../controllers/playlists.controller.js'
import { requireAuth } from '../middleware/auth.js'
import { requireSpotify } from '../middleware/requireSpotify.js'

const router = Router()

// All playlist routes require Spotify to be connected
router.get('/spotify/available', requireAuth, requireSpotify, playlistsController.getAvailablePlaylists)
router.post('/import', requireAuth, requireSpotify, playlistsController.importPlaylists)

router.get('/user/:userId', playlistsController.getUserPlaylists)
router.delete('/:playlistId', requireAuth, playlistsController.deletePlaylist)

export default router
