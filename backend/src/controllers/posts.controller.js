import * as postsService from '../services/posts.service.js'
import { success } from '../utils/response.js'

export const createPost = async (req, res, next) => {
  try {
    const post = await postsService.createPost(req.user.id, req.validatedBody)
    success(res, post, 201)
  } catch (err) {
    next(err)
  }
}

export const getFeed = async (req, res, next) => {
  try {
    const posts = await postsService.getFeed(req.user.id, req.query)
    success(res, posts)
  } catch (err) {
    next(err)
  }
}

export const likePost = async (req, res, next) => {
  try {
    const result = await postsService.likePost(req.user.id, req.params.postId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

export const unlikePost = async (req, res, next) => {
  try {
    const result = await postsService.unlikePost(req.user.id, req.params.postId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

export const addComment = async (req, res, next) => {
  try {
    const comment = await postsService.addComment(req.user.id, req.params.postId, req.validatedBody.content)
    success(res, comment, 201)
  } catch (err) {
    next(err)
  }
}

export const getComments = async (req, res, next) => {
  try {
    const comments = await postsService.getComments(req.params.postId, req.query)
    success(res, comments)
  } catch (err) {
    next(err)
  }
}

export const hidePost = async (req, res, next) => {
  try {
    const result = await postsService.hidePost(req.user.id, req.params.postId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

export const reportPost = async (req, res, next) => {
  try {
    const result = await postsService.reportPost(req.user.id, req.params.postId, req.validatedBody.reason)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

export const deletePost = async (req, res, next) => {
  try {
    const result = await postsService.deletePost(req.user.id, req.params.postId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}
