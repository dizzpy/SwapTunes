import { Router } from 'express'
import * as postsController from '../controllers/posts.controller.js'
import { requireAuth } from '../middleware/auth.js'
import { validate } from '../middleware/validate.js'
import { postSchema, commentSchema, reportSchema } from '../validators/posts.schema.js'

const router = Router()

// Feed & Create
router.get('/feed', requireAuth, postsController.getFeed)
router.post('/', requireAuth, validate(postSchema), postsController.createPost)
router.delete('/:postId', requireAuth, postsController.deletePost)

// Interact
router.post('/:postId/like', requireAuth, postsController.likePost)
router.delete('/:postId/like', requireAuth, postsController.unlikePost)
router.post('/:postId/hide', requireAuth, postsController.hidePost)
router.post('/:postId/report', requireAuth, validate(reportSchema), postsController.reportPost)

// Comments
router.get('/:postId/comments', requireAuth, postsController.getComments)
router.post('/:postId/comments', requireAuth, validate(commentSchema), postsController.addComment)

export default router
