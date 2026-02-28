import { supabase } from '../config/supabase.js'
import { notificationsService } from './notifications.service.js'
import { getPagination } from '../utils/pagination.js'

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

export const getFeed = async (userId, query) => {
  const { from, to } = getPagination(query.page, query.limit)

  // A real feed would combine followed users and suggested.
  // For now, we'll just get all posts not hidden by the user.
  // To exclude hidden posts we'll do it locally or via a subquery.
  // Wait, Supabase lets us query posts and we can just get recent ones for the scope of mvp.

  // Fetch hidden post IDs
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

export const likePost = async (userId, postId) => {
  const { error } = await supabase.from('post_likes').insert({ post_id: postId, user_id: userId })

  if (error) {
    if (error.code === '23505') throw { statusCode: 400, code: 'ALREADY_LIKED', message: 'You already liked this post' }
    throw { statusCode: 400, code: 'LIKE_FAILED', message: error.message }
  }

  // Increment denormalized counter
  await supabase.rpc('increment_likes', { p_id: postId })

  // Get post owner for notification
  const { data: post } = await supabase.from('posts').select('user_id').eq('id', postId).single()
  if (post && post.user_id) {
    const postOwnerId = post.user_id
    await notificationsService.createNotification({
      userId: postOwnerId,
      actorId: userId,
      type: 'like',
      referenceId: postId
    })
  }

  return { success: true }
}

export const unlikePost = async (userId, postId) => {
  const { error } = await supabase.from('post_likes').delete().match({ post_id: postId, user_id: userId })
  if (error) throw { statusCode: 400, code: 'UNLIKE_FAILED', message: error.message }

  await supabase.rpc('decrement_likes', { p_id: postId })
  return { success: true }
}

export const addComment = async (userId, postId, content) => {
  const { data: comment, error } = await supabase
    .from('comments')
    .insert([{ post_id: postId, user_id: userId, content }])
    .select('*, user:users(id, username, full_name, avatar_url)')
    .single()

  if (error) throw { statusCode: 400, code: 'COMMENT_FAILED', message: error.message }

  await supabase.rpc('increment_comments', { p_id: postId })

  const { data: post } = await supabase.from('posts').select('user_id').eq('id', postId).single()
  if (post && post.user_id) {
    const postOwnerId = post.user_id
    await notificationsService.createNotification({
      userId: postOwnerId,
      actorId: userId,
      type: 'comment',
      referenceId: postId
    })
  }

  return comment
}

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

export const hidePost = async (userId, postId) => {
  const { error } = await supabase.from('hidden_posts').insert([{ user_id: userId, post_id: postId }])
  if (error && error.code !== '23505') throw { statusCode: 400, code: 'HIDE_FAILED', message: error.message }
  return { success: true }
}

export const reportPost = async (userId, postId, reason) => {
  const { error } = await supabase.from('post_reports').insert([{ reporter_id: userId, post_id: postId, reason }])
  if (error) throw { statusCode: 400, code: 'REPORT_FAILED', message: error.message }
  return { success: true }
}
