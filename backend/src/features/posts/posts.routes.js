import { Router } from 'express'
import * as postsController from './posts.controller.js'
import { requireAuth } from '../../shared/middleware/auth.js'
import { validate, validateParams } from '../../shared/middleware/validate.js'
import {
  postSchema,
  commentSchema,
  reportSchema,
  updatePostSchema,
  updateCommentSchema,
  postParamSchema,
  commentParamSchema
} from './posts.schema.js'

const router = Router()

// Feed & Create
router.get('/feed', requireAuth, postsController.getFeed)
router.post('/', requireAuth, validate(postSchema), postsController.createPost)
router.patch(
  '/:postId',
  requireAuth,
  validateParams(postParamSchema),
  validate(updatePostSchema),
  postsController.updatePost
)
router.delete('/:postId', requireAuth, validateParams(postParamSchema), postsController.deletePost)

// Interact
router.post('/:postId/like', requireAuth, validateParams(postParamSchema), postsController.likePost)
router.delete('/:postId/like', requireAuth, validateParams(postParamSchema), postsController.unlikePost)
router.post('/:postId/hide', requireAuth, validateParams(postParamSchema), postsController.hidePost)
router.post(
  '/:postId/report',
  requireAuth,
  validateParams(postParamSchema),
  validate(reportSchema),
  postsController.reportPost
)

// Comments
router.get('/:postId/comments', requireAuth, validateParams(postParamSchema), postsController.getComments)
router.post(
  '/:postId/comments',
  requireAuth,
  validateParams(postParamSchema),
  validate(commentSchema),
  postsController.addComment
)
router.patch(
  '/:postId/comments/:commentId',
  requireAuth,
  validateParams(commentParamSchema),
  validate(updateCommentSchema),
  postsController.updateComment
)
router.delete(
  '/:postId/comments/:commentId',
  requireAuth,
  validateParams(commentParamSchema),
  postsController.deleteComment
)

// Likers
router.get('/:postId/likers', requireAuth, validateParams(postParamSchema), postsController.getLikers)

export default router
