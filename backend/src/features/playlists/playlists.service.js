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
    is_public: item.public === true
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
  const { data: existing } = await supabase.from('playlists').select('spotify_playlist_id').eq('user_id', user.id)
  const existingIds = existing ? existing.map((e) => e.spotify_playlist_id) : []

  return items.map((item) => ({
    id: item.id,
    name: item.name,
    track_count: item.tracks.total,
    is_public: item.public,
    cover_image_url: item.images && item.images.length > 0 ? item.images[0].url : null,
    is_imported: existingIds.includes(item.id)
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

// Delete playlist service method interacting with the database.
export const deletePlaylist = async (userId, playlistId) => {
  const { error } = await supabase.from('playlists').delete().match({ id: playlistId, user_id: userId })
  if (error) throw { statusCode: 400, code: 'DELETE_FAILED', message: error.message }
  return { success: true }
}
