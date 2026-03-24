import { supabase } from '../../config/supabase.js'
import { getValidAccessToken, fetchSpotifyPlaylists } from '../../shared/services/spotify.service.js'

// Import playlists service method interacting with the database.
export const importPlaylists = async (user, playlistIds) => {
  // Get spotify access token
  const token = await getValidAccessToken(user)

  // Fetch from Spotify
  const items = await fetchSpotifyPlaylists(token)

  // Filter selected
  const toImport = items.filter((item) => playlistIds.includes(item.id))

  if (toImport.length === 0) return []

  // Map to DB format
  const dbPlaylists = toImport.map((item) => ({
    user_id: user.id,
    spotify_playlist_id: item.id,
    name: item.name,
    description: item.description || null,
    cover_image_url: item.images && item.images.length > 0 ? item.images[0].url : null,
    track_count: item.tracks.total,
    is_public: item.public === true,
    source_platform: 'spotify',
    primary_url: `https://open.spotify.com/playlist/${item.id}`,
  }))

  // Insert or upsert
  const { data, error } = await supabase
    .from('playlists')
    .upsert(dbPlaylists, { onConflict: 'spotify_playlist_id' })
    .select()

  if (error) throw { statusCode: 400, code: 'IMPORT_FAILED', message: error.message }

  return data
}

// Get available spotify playlists service method interacting with the database.
export const getAvailableSpotifyPlaylists = async (user) => {
  const token = await getValidAccessToken(user)
  const items = await fetchSpotifyPlaylists(token)

  // fetch already imported
  const { data: existing } = await supabase
    .from('playlists')
    .select('spotify_playlist_id')
    .eq('user_id', user.id)
  const existingIds = existing ? existing.map((e) => e.spotify_playlist_id).filter(Boolean) : []

  return items.map((item) => ({
    id: item.id,
    name: item.name,
    track_count: item.tracks.total,
    is_public: item.public,
    cover_image_url: item.images && item.images.length > 0 ? item.images[0].url : null,
    is_imported: existingIds.includes(item.id),
  }))
}

// Get user playlists service method interacting with the database.
export const getUserPlaylists = async (userId) => {
  const { data, error } = await supabase
    .from('playlists')
    .select('*')
    .eq('user_id', userId)
    .eq('is_public', true)
    .order('created_at', { ascending: false })

  if (error) throw { statusCode: 400, code: 'FETCH_FAILED', message: error.message }
  return data
}

// Get single playlist by ID service method interacting with the database.
export const getPlaylistById = async (playlistId) => {
  const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  if (!uuidPattern.test(playlistId)) {
    throw { statusCode: 400, code: 'INVALID_ID', message: 'Invalid playlist ID format' }
  }

  const { data, error } = await supabase
    .from('playlists')
    .select('*, user:users(id, username, full_name, avatar_url)')
    .eq('id', playlistId)
    .single()

  if (error) throw { statusCode: 404, code: 'NOT_FOUND', message: 'Playlist not found' }
  return data
}

// Create manual playlist service method interacting with the database.
export const createPlaylist = async (userId, data) => {
  const insert = {
    user_id: userId,
    name: data.name.trim(),
    description: data.description || null,
    cover_image_url: data.cover_image_url || null,
    is_public: data.is_public ?? true,
    source_platform: data.source_platform || 'other',
    primary_url: data.primary_url || null,
    genre_tags: data.genre_tags || [],
    artists: data.artists || [],
    mood_tags: data.mood_tags || [],
    era: data.era || null,
    energy_level: data.energy_level ?? null,
    occasion_tags: data.occasion_tags ?? [],
    vocal_style: data.vocal_style ?? null,
    language: data.language ?? null,
    track_count: data.track_count ?? 0,
  }

  const { data: created, error } = await supabase
    .from('playlists')
    .insert(insert)
    .select('*, user:users(id, username, full_name, avatar_url)')
    .single()

  if (error) throw { statusCode: 400, code: 'CREATE_FAILED', message: error.message }
  return created
}

// Update playlist service method interacting with the database.
export const updatePlaylist = async (userId, playlistId, data) => {
  if (data.name !== undefined && !String(data.name).trim()) {
    throw { statusCode: 400, code: 'VALIDATION_FAILED', message: 'name cannot be empty' }
  }

  const allowed = [
    'name',
    'description',
    'cover_image_url',
    'is_public',
    'source_platform',
    'primary_url',
    'genre_tags',
    'artists',
    'mood_tags',
    'era',
    'energy_level',
    'occasion_tags',
    'vocal_style',
    'language',
    'track_count',
  ]

  const update = {}
  for (const key of allowed) {
    if (data[key] !== undefined) update[key] = data[key]
  }
  update.updated_at = new Date().toISOString()

  const { data: updated, error } = await supabase
    .from('playlists')
    .update(update)
    .match({ id: playlistId, user_id: userId })
    .select('*, user:users(id, username, full_name, avatar_url)')
    .single()

  if (error) throw { statusCode: 400, code: 'UPDATE_FAILED', message: error.message }
  if (!updated) throw { statusCode: 403, code: 'FORBIDDEN', message: 'Not authorised or playlist not found' }
  return updated
}

// Delete playlist service method interacting with the database.
export const deletePlaylist = async (userId, playlistId) => {
  const { error } = await supabase.from('playlists').delete().match({ id: playlistId, user_id: userId })
  if (error) throw { statusCode: 400, code: 'DELETE_FAILED', message: error.message }
  return { success: true }
}

// Like playlist service method interacting with the database.
export const likePlaylist = async (userId, playlistId) => {
  const { error } = await supabase
    .from('playlist_likes')
    .insert({ user_id: userId, playlist_id: playlistId })

  if (error) {
    // 23505 = unique_violation — already liked, treat as success
    if (error.code === '23505') return { success: true }
    throw { statusCode: 400, code: 'LIKE_FAILED', message: error.message }
  }

  await supabase.rpc('increment_playlist_likes', { p_id: playlistId })
  return { success: true }
}

// Unlike playlist service method interacting with the database.
export const unlikePlaylist = async (userId, playlistId) => {
  const { data: deleted, error } = await supabase
    .from('playlist_likes')
    .delete()
    .match({ user_id: userId, playlist_id: playlistId })
    .select()

  if (error) throw { statusCode: 400, code: 'UNLIKE_FAILED', message: error.message }

  // Only decrement if a row was actually deleted
  if (deleted && deleted.length > 0) {
    await supabase.rpc('decrement_playlist_likes', { p_id: playlistId })
  }
  return { success: true }
}
