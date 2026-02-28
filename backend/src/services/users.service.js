import { supabase } from '../config/supabase.js'
import { notificationsService } from './notifications.service.js'
import { getPagination } from '../utils/pagination.js'

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

export const updateProfile = async (userId, data) => {
  const { genres, ...updates } = data

  if (Object.keys(updates).length > 0) {
    const { error } = await supabase.from('users').update(updates).eq('id', userId)
    if (error) throw { statusCode: 400, code: 'UPDATE_FAILED', message: error.message }
  }

  // Update genres if provided
  if (genres && Array.isArray(genres)) {
    // delete old ones
    await supabase.from('user_genres').delete().eq('user_id', userId)
    // insert new ones
    if (genres.length > 0) {
      const inserts = genres.map((g) => ({ user_id: userId, genre: g }))
      const { error: genreErr } = await supabase.from('user_genres').insert(inserts)
      if (genreErr) throw { statusCode: 400, code: 'GENRE_UPDATE_FAILED', message: genreErr.message }
    }
  }

  return { success: true }
}

export const getFollowers = async (userId, query) => {
  const { from, to } = getPagination(query.page, query.limit)

  const { data, error } = await supabase
    .from('follows')
    .select('follower:users!follows_follower_id_fkey(id, full_name, username, avatar_url)')
    .eq('following_id', userId)
    .order('created_at', { ascending: false })
    .range(from, to)

  if (error) throw { statusCode: 400, code: 'FETCH_FAILED', message: error.message }

  return data.map((d) => d.follower)
}

export const getFollowing = async (userId, query) => {
  const { from, to } = getPagination(query.page, query.limit)

  const { data, error } = await supabase
    .from('follows')
    .select('following:users!follows_following_id_fkey(id, full_name, username, avatar_url)')
    .eq('follower_id', userId)
    .order('created_at', { ascending: false })
    .range(from, to)

  if (error) throw { statusCode: 400, code: 'FETCH_FAILED', message: error.message }

  return data.map((d) => d.following)
}
