import { supabase } from '../config/supabase.js'
import { getPagination } from '../utils/pagination.js'

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

export const search = async (queryTerm, type = 'all', queryParams) => {
  const { from, to } = getPagination(queryParams.page, queryParams.limit)
  const results = {}

  const term = `%${queryTerm}%`

  if (type === 'all' || type === 'users') {
    const { data: users } = await supabase
      .from('users')
      .select('id, username, full_name, avatar_url, user_type')
      .ilike('username', term)
      .range(from, to)
    results.users = users || []
  }

  if (type === 'all' || type === 'playlists') {
    const { data: playlists } = await supabase
      .from('playlists')
      .select('*, user:users(username, full_name)')
      .ilike('name', term)
      .eq('is_public', true)
      .range(from, to)
    results.playlists = playlists || []
  }

  if (type === 'all' || type === 'creators') {
    const { data: creators } = await supabase
      .from('creator_profiles')
      .select('*, user:users(id, username, full_name, avatar_url)')
      .ilike('role_title', term)
      .range(from, to)
    results.creators = creators || []
  }

  return results
}
