import { Router } from 'express'
import * as usersController from './users.controller.js'
import * as postsController from '../posts/posts.controller.js'
import * as collabsController from '../collabs/collabs.controller.js'
import { requireAuth } from '../../shared/middleware/auth.js'

const router = Router()

// Self profile update
router.patch('/me', requireAuth, usersController.updateProfile)

// Self account deletion
router.delete('/me', requireAuth, usersController.deleteAccount)

// Publicly readable? (depends on privacy, let's keep it under requireAuth for now so we know who is requesting)
router.get('/:username', requireAuth, usersController.getProfile)

// User's posts
router.get('/:userId/posts', requireAuth, postsController.getUserPosts)

// User's collabs (for profile view)
router.get('/:userId/collabs', requireAuth, collabsController.getUserCollabs)

// Lists of follows
router.get('/:userId/followers', requireAuth, usersController.getFollowers)
router.get('/:userId/following', requireAuth, usersController.getFollowing)

// User's saved song plans
router.get('/:userId/songs', requireAuth, usersController.getUserSongs)

// Follow / Unfollow logic
router.post('/:userId/follow', requireAuth, usersController.followUser)
router.delete('/:userId/unfollow', requireAuth, usersController.unfollowUser)

export default router
