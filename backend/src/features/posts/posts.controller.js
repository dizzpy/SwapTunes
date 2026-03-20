import * as postsService from './posts.service.js'
import { success } from '../../shared/utils/response.js'

// Create post controller handler.
export const createPost = async (req, res, next) => {
  try {
    const post = await postsService.createPost(req.user.id, req.validatedBody)
    success(res, post, 201)
  } catch (err) {
    next(err)
  }
}

// Get feed controller handler.
export const getFeed = async (req, res, next) => {
  try {
    const posts = await postsService.getFeed(req.user.id, req.query)
    success(res, posts)
  } catch (err) {
    next(err)
  }
}

// Like post controller handler.
export const likePost = async (req, res, next) => {
  try {
    const result = await postsService.likePost(req.user.id, req.params.postId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

// Unlike post controller handler.
export const unlikePost = async (req, res, next) => {
  try {
    const result = await postsService.unlikePost(req.user.id, req.params.postId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

// Add comment controller handler.
export const addComment = async (req, res, next) => {
  try {
    const comment = await postsService.addComment(req.user.id, req.params.postId, req.validatedBody.content)
    success(res, comment, 201)
  } catch (err) {
    next(err)
  }
}

// Get comments controller handler.
export const getComments = async (req, res, next) => {
  try {
    const comments = await postsService.getComments(req.params.postId, req.query)
    success(res, comments)
  } catch (err) {
    next(err)
  }
}

// Hide post controller handler.
export const hidePost = async (req, res, next) => {
  try {
    const result = await postsService.hidePost(req.user.id, req.params.postId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

// Report post controller handler.
export const reportPost = async (req, res, next) => {
  try {
    const result = await postsService.reportPost(req.user.id, req.params.postId, req.validatedBody.reason)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

// Update post controller handler.
export const updatePost = async (req, res, next) => {
  try {
    const post = await postsService.updatePost(req.user.id, req.params.postId, req.validatedBody)
    success(res, post)
  } catch (err) {
    next(err)
  }
}

// Delete post controller handler.
export const deletePost = async (req, res, next) => {
  try {
    const result = await postsService.deletePost(req.user.id, req.params.postId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

// Update comment controller handler.
export const updateComment = async (req, res, next) => {
  try {
    const comment = await postsService.updateComment(req.user.id, req.params.commentId, req.validatedBody.content)
    success(res, comment)
  } catch (err) {
    next(err)
  }
}

// Delete comment controller handler.
export const deleteComment = async (req, res, next) => {
  try {
    const result = await postsService.deleteComment(req.user.id, req.params.commentId, req.params.postId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

// Get post likers controller handler.
export const getLikers = async (req, res, next) => {
  try {
    const result = await postsService.getLikers(req.params.postId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}
