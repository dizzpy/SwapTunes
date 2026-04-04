import { supabase } from '../../config/supabase.js'
import { getPagination } from '../../shared/utils/pagination.js'

// Get all unique genre tags service method interacting with the database.
export const getGenres = async () => {
  const [{ data: playlists, error: e1 }, { data: userGenres, error: e2 }] = await Promise.all([
    supabase.from('playlists').select('genre_tags').eq('is_public', true),
    supabase.from('user_genres').select('genre'),
  ])

  if (e1) throw { statusCode: 400, code: 'FETCH_GENRES_FAILED', message: e1.message }
  if (e2) throw { statusCode: 400, code: 'FETCH_GENRES_FAILED', message: e2.message }

  const fromPlaylists = (playlists || []).flatMap((r) => r.genre_tags || [])
  const fromUsers = (userGenres || []).map((r) => r.genre)

  const unique = [...new Set([...fromPlaylists, ...fromUsers].map((g) => g.trim()).filter(Boolean))]
  return unique.sort((a, b) => a.localeCompare(b))
}

// Get discover playlists service method interacting with the database.
export const getDiscoverPlaylists = async (query) => {
  const { from, to } = getPagination(query.page, query.limit)

  let qb = supabase.from('playlists').select('*, user:users(username, full_name, avatar_url)').eq('is_public', true)

  if (query.genre) {
    qb = qb.contains('genre_tags', [query.genre])
  }

  const { data, error } = await qb.range(from, to)

  if (error) throw { statusCode: 400, code: 'FETCH_DISCOVER_FAILED', message: error.message }
  return data
}

// Get suggested users service method interacting with the database.
export const getSuggestedUsers = async (userId, limit = 20) => {
  // Get IDs the current user already follows
  const { data: following, error: followErr } = await supabase
    .from('follows')
    .select('following_id')
    .eq('follower_id', userId)

  if (followErr) throw { statusCode: 400, code: 'FETCH_SUGGESTED_USERS_FAILED', message: followErr.message }

  const followingIds = (following || []).map((f) => f.following_id)
  const excludeIds = [userId, ...followingIds]

  let qb = supabase
    .from('users')
    .select('id, username, full_name, avatar_url, user_type')
    .limit(limit)

  qb = qb.not('id', 'in', `(${excludeIds.join(',')})`)

  const { data, error } = await qb
  if (error) throw { statusCode: 400, code: 'FETCH_SUGGESTED_USERS_FAILED', message: error.message }
  return data || []
}

// Get trending genres sorted by playlist count.
export const getTrendingGenres = async (limit = 10) => {
  const { data: playlists, error } = await supabase
    .from('playlists')
    .select('genre_tags')
    .eq('is_public', true)

  if (error) throw { statusCode: 400, code: 'FETCH_TRENDING_FAILED', message: error.message }

  const genreCount = {}
  for (const playlist of playlists || []) {
    for (const genre of playlist.genre_tags || []) {
      const trimmed = genre.trim()
      if (trimmed) {
        genreCount[trimmed] = (genreCount[trimmed] || 0) + 1
      }
    }
  }

  return Object.entries(genreCount)
    .sort(([, a], [, b]) => b - a)
    .slice(0, limit)
    .map(([genre]) => genre)
}

// Search service method interacting with the database.
export const search = async (queryTerm, type = 'all', queryParams) => {
  const { from, to } = getPagination(queryParams.page, queryParams.limit)
  const results = {}

  const term = `%${queryTerm}%`

  if (type === 'all' || type === 'users') {
    const { data: users, error: usersErr } = await supabase
      .from('users')
      .select('id, username, full_name, avatar_url, user_type')
      .ilike('username', term)
      .range(from, to)
    if (usersErr) throw { statusCode: 400, code: 'SEARCH_FAILED', message: usersErr.message }
    results.users = users || []
  }

  if (type === 'all' || type === 'playlists') {
    const { data: playlists, error: playlistsErr } = await supabase
      .from('playlists')
      .select('*, user:users(username, full_name)')
      .ilike('name', term)
      .eq('is_public', true)
      .range(from, to)
    if (playlistsErr) throw { statusCode: 400, code: 'SEARCH_FAILED', message: playlistsErr.message }
    results.playlists = playlists || []
  }

  if (type === 'all' || type === 'creators') {
    const { data: creators, error: creatorsErr } = await supabase
      .from('creator_profiles')
      .select('*, user:users(id, username, full_name, avatar_url)')
      .ilike('role_title', term)
      .range(from, to)
    if (creatorsErr) throw { statusCode: 400, code: 'SEARCH_FAILED', message: creatorsErr.message }
    results.creators = creators || []
  }

  return results
}
