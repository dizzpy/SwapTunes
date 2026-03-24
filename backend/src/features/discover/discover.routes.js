import { Router } from 'express'
import * as discoverController from './discover.controller.js'
import { requireAuth } from '../../shared/middleware/auth.js'

const router = Router()

router.get('/genres', requireAuth, discoverController.getGenres)
router.get('/playlists', requireAuth, discoverController.discoverPlaylists)
router.get('/search', requireAuth, discoverController.search)

export default router
