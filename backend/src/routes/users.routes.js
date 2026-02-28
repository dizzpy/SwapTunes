import { Router } from 'express'
import * as usersController from '../controllers/users.controller.js'
import { requireAuth } from '../middleware/auth.js'

const router = Router()

// Publicly readable? (depends on privacy, let's keep it under requireAuth for now so we know who is requesting)
router.get('/:username', requireAuth, usersController.getProfile)

// Follow / Unfollow logic
router.post('/:userId/follow', requireAuth, usersController.followUser)
router.delete('/:userId/unfollow', requireAuth, usersController.unfollowUser)

export default router
