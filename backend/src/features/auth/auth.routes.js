import { Router } from 'express'
import * as authController from './auth.controller.js'
import { requireAuth } from '../../shared/middleware/auth.js'
import { requireJwtAuth } from '../../shared/middleware/requireJwtAuth.js'
import { validate } from '../../shared/middleware/validate.js'
import { profileSetupSchema, spotifyConnectSchema } from './auth.schema.js'

const router = Router()

// Verify JWT and Setup profile in public.users
router.post('/profile/setup', requireJwtAuth, validate(profileSetupSchema), authController.setupProfile)

// Verify full Auth and Connect Spotify
router.post('/spotify/connect', requireAuth, validate(spotifyConnectSchema), authController.connectSpotify)

// Get my user details
router.get('/me', requireAuth, authController.getMe)

export default router
