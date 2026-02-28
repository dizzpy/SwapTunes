import { supabase } from '../config/supabase.js'
import { notificationsService } from './notifications.service.js'

export const getProfile = async (username) => {
  const { data, error } = await supabase
    .from('users')
    .select(
      `
      *,
      creator_profiles(*),
      user_genres(genre)
    `
    )
    .eq('username', username)
    .single()

  if (error || !data) throw { statusCode: 404, code: 'NOT_FOUND', message: 'User not found' }

  // Format genres array
  data.genres = data.user_genres.map((g) => g.genre)
  delete data.user_genres
  delete data.spotify_access_token
  delete data.spotify_refresh_token

  // Get follow stats
  const { count: followersCount } = await supabase
    .from('follows')
    .select('*', { count: 'exact', head: true })
    .eq('following_id', data.id)
  const { count: followingCount } = await supabase
    .from('follows')
    .select('*', { count: 'exact', head: true })
    .eq('follower_id', data.id)
  const { count: postsCount } = await supabase
    .from('posts')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', data.id)
  const { count: playlistsCount } = await supabase
    .from('playlists')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', data.id)

  let collabsCount = 0
  if (data.user_type === 'creator') {
    const { count } = await supabase
      .from('collaborations')
      .select('*', { count: 'exact', head: true })
      .eq('creator_id', data.id)
    collabsCount = count
  }

  data.stats = {
    followers: followersCount || 0,
    following: followingCount || 0,
    posts: postsCount || 0,
    playlists: playlistsCount || 0,
    collabs: collabsCount || 0
  }

  return data
}

export const followUser = async (followerId, followingId) => {
  if (followerId === followingId) throw { statusCode: 400, code: 'INVALID', message: 'Cannot follow yourself' }

  const { error } = await supabase.from('follows').insert({
    follower_id: followerId,
    following_id: followingId
  })

  if (error) {
    if (error.code === '23505') throw { statusCode: 400, code: 'ALREADY_FOLLOWING', message: 'Already following user' }
    throw { statusCode: 400, code: 'FOLLOW_FAILED', message: error.message }
  }

  // Create notification
  await notificationsService.createNotification({
    userId: followingId,
    actorId: followerId,
    type: 'follow',
    referenceId: null
  })

  return { success: true }
}

export const unfollowUser = async (followerId, followingId) => {
  const { error } = await supabase
    .from('follows')
    .delete()
    .match({ follower_id: followerId, following_id: followingId })
  if (error) throw { statusCode: 400, code: 'UNFOLLOW_FAILED', message: error.message }
  return { success: true }
}
