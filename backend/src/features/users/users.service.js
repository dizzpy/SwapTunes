import { supabase } from '../../config/supabase.js'
import { notificationsService } from '../notifications/notifications.service.js'
import { getPagination } from '../../shared/utils/pagination.js'

// Get saved song plans for a user profile (public — shown on profile Songs tab).
export const getUserSongs = async (userId) => {
  const { data, error } = await supabase
    .from('saved_song_plans')
    .select('id, title, data, created_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })

  if (error) throw { statusCode: 400, code: 'FETCH_FAILED', message: error.message }

  return data ?? []
}

// Get profile service method interacting with the database.
export const getProfile = async (username, requesterId) => {
  const { data, error } = await supabase
    .from('users')
    .select(
      `
      *,
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

  // Fetch creator_profiles separately so a join RLS issue never kills the whole query
  data.creator_profiles = []
  if (data.user_type === 'creator') {
    const { data: cp } = await supabase.from('creator_profiles').select('*').eq('user_id', data.id).maybeSingle()
    if (cp) data.creator_profiles = [cp]
  }

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
    try {
      const { count } = await supabase
        .from('collaborations')
        .select('*', { count: 'exact', head: true })
        .eq('creator_id', data.id)
      collabsCount = count ?? 0
    } catch {
      collabsCount = 0
    }
  }

  data.stats = {
    followers: followersCount || 0,
    following: followingCount || 0,
    posts: postsCount || 0,
    playlists: playlistsCount || 0,
    collabs: collabsCount || 0
  }

  // Check if requester follows this user (null for own profile)
  if (requesterId && requesterId !== data.id) {
    const { count: followCount } = await supabase
      .from('follows')
      .select('*', { count: 'exact', head: true })
      .eq('follower_id', requesterId)
      .eq('following_id', data.id)
    data.is_following = (followCount || 0) > 0
  } else {
    data.is_following = null
  }

  return data
}

// Follow user service method interacting with the database.
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

// Unfollow user service method interacting with the database.
export const unfollowUser = async (followerId, followingId) => {
  const { error } = await supabase
    .from('follows')
    .delete()
    .match({ follower_id: followerId, following_id: followingId })
  if (error) throw { statusCode: 400, code: 'UNFOLLOW_FAILED', message: error.message }
  return { success: true }
}

// Update profile service method interacting with the database.
export const updateProfile = async (userId, data) => {
  const { genres, username, ...rest } = data
  const updates = { ...rest }

  // Username change — enforce 7-day cooldown
  if (username !== undefined) {
    const { data: user, error: fetchErr } = await supabase
      .from('users')
      .select('username, username_changed_at')
      .eq('id', userId)
      .single()

    if (fetchErr) throw { statusCode: 400, code: 'FETCH_FAILED', message: fetchErr.message }

    if (user.username_changed_at) {
      const daysSince = (Date.now() - new Date(user.username_changed_at).getTime()) / (1000 * 60 * 60 * 24)
      if (daysSince < 7) {
        const daysLeft = Math.ceil(7 - daysSince)
        throw {
          statusCode: 429,
          code: 'USERNAME_COOLDOWN',
          message: `You can change your username in ${daysLeft} day${daysLeft === 1 ? '' : 's'}.`
        }
      }
    }

    updates.username = username
    updates.username_changed_at = new Date().toISOString()
  }

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

// Delete account service method — removes the user and all related data.
export const deleteAccount = async (userId) => {
  // Delete the public users row first. All user-owned data (genres, posts, follows,
  // playlists, collabs, conversations, messages, notifications, ...) cascades from here.
  // The auth.users FK has no cascade, so this must happen before deleting the auth user.
  const { error: deleteErr } = await supabase.from('users').delete().eq('id', userId)
  if (deleteErr) throw { statusCode: 400, code: 'DELETE_FAILED', message: deleteErr.message }

  // Remove the Supabase auth identity so the email/account is fully released.
  const { error: authErr } = await supabase.auth.admin.deleteUser(userId)
  if (authErr) throw { statusCode: 400, code: 'AUTH_DELETE_FAILED', message: authErr.message }

  return { success: true }
}

// Get followers service method interacting with the database.
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

// Get following service method interacting with the database.
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
