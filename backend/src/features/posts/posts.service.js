import { supabase } from '../../config/supabase.js'
import { logger } from '../../shared/utils/logger.js'
import { notificationsService } from '../notifications/notifications.service.js'
import { getPagination } from '../../shared/utils/pagination.js'

// Create post service method interacting with the database.
export const createPost = async (userId, data) => {
  const { data: post, error } = await supabase
    .from('posts')
    .insert([
      {
        user_id: userId,
        content: data.content,
        image_url: data.image_url
      }
    ])
    .select('*, user:users(id, username, full_name, avatar_url, is_verified)')
    .single()

  if (error) throw { statusCode: 400, code: 'CREATE_POST_FAILED', message: error.message }
  return post
}

// Get feed service method interacting with the database.
export const getFeed = async (userId, query) => {
  const { from, to } = getPagination(query.page, query.limit)

  // Fetch hidden post IDs so we can exclude them from the feed.
  const { data: hidden } = await supabase.from('hidden_posts').select('post_id').eq('user_id', userId)
  const hiddenIds = hidden ? hidden.map((h) => h.post_id) : []

  let queryBuilder = supabase
    .from('posts')
    .select('*, user:users(id, username, full_name, avatar_url, is_verified), post_likes(user_id)')
    .order('created_at', { ascending: false })
    .range(from, to)

  if (hiddenIds.length > 0) {
    queryBuilder = queryBuilder.not('id', 'in', `(${hiddenIds.join(',')})`)
  }

  const { data: posts, error } = await queryBuilder

  if (error) throw { statusCode: 400, code: 'FETCH_FEED_FAILED', message: error.message }

  // Check if current user liked each post
  const mapped = posts.map((p) => ({
    ...p,
    is_liked: p.post_likes.some((like) => like.user_id === userId),
    post_likes: undefined // remove the array
  }))

  return mapped
}

// Like post service method interacting with the database.
export const likePost = async (userId, postId) => {
  const { data, error } = await supabase
    .from('post_likes')
    .upsert({ post_id: postId, user_id: userId }, { ignoreDuplicates: true })
    .select()

  if (error) throw { statusCode: 400, code: 'LIKE_FAILED', message: error.message }

  // If no row was returned, the like already existed — skip counter + notification.
  if (!data || data.length === 0) return { success: true }

  // Increment denormalized counter
  const { error: rpcError } = await supabase.rpc('increment_likes', { p_id: postId })
  if (rpcError) logger.error('[likePost] increment_likes RPC failed:', rpcError.message)

  // Best-effort notification — failures must not break the like action.
  try {
    const { data: post } = await supabase.from('posts').select('user_id').eq('id', postId).single()
    if (post && post.user_id) {
      await notificationsService.createNotification({
        userId: post.user_id,
        actorId: userId,
        type: 'like',
        referenceId: postId
      })
    }
  } catch (_) { /* notification is non-critical */ }

  return { success: true }
}

// Unlike post service method interacting with the database.
export const unlikePost = async (userId, postId) => {
  const { error } = await supabase.from('post_likes').delete().match({ post_id: postId, user_id: userId })
  if (error) throw { statusCode: 400, code: 'UNLIKE_FAILED', message: error.message }

  const { error: rpcError } = await supabase.rpc('decrement_likes', { p_id: postId })
  if (rpcError) logger.error('[unlikePost] decrement_likes RPC failed:', rpcError.message)
  return { success: true }
}

// Add comment service method interacting with the database.
export const addComment = async (userId, postId, content) => {
  const { data: comment, error } = await supabase
    .from('comments')
    .insert([{ post_id: postId, user_id: userId, content }])
    .select('*, user:users(id, username, full_name, avatar_url)')
    .single()

  if (error) throw { statusCode: 400, code: 'COMMENT_FAILED', message: error.message }

  const { error: rpcErrorC } = await supabase.rpc('increment_comments', { p_id: postId })
  if (rpcErrorC) logger.error('[addComment] increment_comments RPC failed:', rpcErrorC.message)

  // Best-effort notification — failures must not break the comment action.
  try {
    const { data: post } = await supabase.from('posts').select('user_id').eq('id', postId).single()
    if (post && post.user_id) {
      await notificationsService.createNotification({
        userId: post.user_id,
        actorId: userId,
        type: 'comment',
        referenceId: postId
      })
    }
  } catch (_) { /* notification is non-critical */ }

  return comment
}

// Get comments service method interacting with the database.
export const getComments = async (postId, query) => {
  const { from, to } = getPagination(query.page, query.limit)

  const { data, error } = await supabase
    .from('comments')
    .select('*, user:users(id, username, full_name, avatar_url)')
    .eq('post_id', postId)
    .order('created_at', { ascending: true })
    .range(from, to)

  if (error) throw { statusCode: 400, code: 'FETCH_COMMENTS_FAILED', message: error.message }
  return data
}

// Hide post service method interacting with the database.
export const hidePost = async (userId, postId) => {
  const { error } = await supabase.from('hidden_posts').insert([{ user_id: userId, post_id: postId }])
  if (error && error.code !== '23505') throw { statusCode: 400, code: 'HIDE_FAILED', message: error.message }
  return { success: true }
}

// Report post service method interacting with the database.
export const reportPost = async (userId, postId, reason) => {
  const { error } = await supabase.from('post_reports').insert([{ reporter_id: userId, post_id: postId, reason }])
  if (error) throw { statusCode: 400, code: 'REPORT_FAILED', message: error.message }
  return { success: true }
}

// Update post service method interacting with the database.
export const updatePost = async (userId, postId, data) => {
  // Empty string means "remove image" — store null in the database.
  const payload = { ...data }
  if (payload.image_url === '') payload.image_url = null

  const { data: post, error } = await supabase
    .from('posts')
    .update(payload)
    .match({ id: postId, user_id: userId })
    .select('*, user:users(id, username, full_name, avatar_url, is_verified)')
    .single()

  if (error) throw { statusCode: 400, code: 'UPDATE_POST_FAILED', message: error.message }
  return post
}

// Delete post service method interacting with the database.
export const deletePost = async (userId, postId) => {
  const { error } = await supabase.from('posts').delete().match({ id: postId, user_id: userId })
  if (error) throw { statusCode: 400, code: 'DELETE_FAILED', message: error.message }
  return { success: true }
}

// Update comment service method interacting with the database.
export const updateComment = async (userId, commentId, content) => {
  const { data: comment, error } = await supabase
    .from('comments')
    .update({ content })
    .match({ id: commentId, user_id: userId })
    .select('*, user:users(id, username, full_name, avatar_url)')
    .single()

  if (error) throw { statusCode: 400, code: 'UPDATE_COMMENT_FAILED', message: error.message }
  return comment
}

// Delete comment service method interacting with the database.
export const deleteComment = async (userId, commentId, postId) => {
  const { error } = await supabase.from('comments').delete().match({ id: commentId, user_id: userId })
  if (error) throw { statusCode: 400, code: 'DELETE_COMMENT_FAILED', message: error.message }
  const { error: rpcErrorD } = await supabase.rpc('decrement_comments', { p_id: postId })
  if (rpcErrorD) logger.error('[deleteComment] decrement_comments RPC failed:', rpcErrorD.message)
  return { success: true }
}

// Get post likers service method interacting with the database.
export const getLikers = async (postId) => {
  const { data, error } = await supabase
    .from('post_likes')
    .select('user:users(id, username, full_name, avatar_url)')
    .eq('post_id', postId)
    .limit(50)

  if (error) throw { statusCode: 400, code: 'FETCH_LIKERS_FAILED', message: error.message }
  return data.map((l) => l.user).filter(Boolean)
}
