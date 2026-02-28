import { Router } from 'express'
import * as discoverController from '../controllers/discover.controller.js'
import { requireAuth } from '../middleware/auth.js'

const router = Router()

router.get('/playlists', requireAuth, discoverController.discoverPlaylists)
router.get('/search', requireAuth, discoverController.search)

export default router
