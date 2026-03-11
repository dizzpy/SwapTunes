import { Router } from 'express'
import * as usersController from './users.controller.js'
import { requireAuth } from '../../shared/middleware/auth.js'

const router = Router()

// Self profile update
router.patch('/me', requireAuth, usersController.updateProfile)

// Publicly readable? (depends on privacy, let's keep it under requireAuth for now so we know who is requesting)
router.get('/:username', requireAuth, usersController.getProfile)

// Lists of follows
router.get('/:userId/followers', requireAuth, usersController.getFollowers)
router.get('/:userId/following', requireAuth, usersController.getFollowing)

// Follow / Unfollow logic
router.post('/:userId/follow', requireAuth, usersController.followUser)
router.delete('/:userId/unfollow', requireAuth, usersController.unfollowUser)

export default router
