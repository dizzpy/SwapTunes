import { supabase } from '../config/supabase.js'
import { getValidAccessToken, fetchSpotifyPlaylists } from './spotify.service.js'

export const importPlaylists = async (user, playlistIds) => {
  // Get spotify access token
  const token = await getValidAccessToken(user)
  
  // Fetch from Spotify
  const items = await fetchSpotifyPlaylists(token)
  
  // Filter selected
  const toImport = items.filter(item => playlistIds.includes(item.id))
  
  if (toImport.length === 0) return []

  // Map to DB format
  const dbPlaylists = toImport.map(item => ({
     user_id: user.id,
     spotify_playlist_id: item.id,
     name: item.name,
     description: item.description || null,
     cover_image_url: item.images && item.images.length > 0 ? item.images[0].url : null,
     track_count: item.tracks.total,
     is_public: item.public === true,
  }))

  // Insert or upsert
  const { data, error } = await supabase
    .from('playlists')
    .upsert(dbPlaylists, { onConflict: 'spotify_playlist_id' })
    .select()

  if (error) throw { statusCode: 400, code: 'IMPORT_FAILED', message: error.message }

  return data
}

export const getAvailableSpotifyPlaylists = async (user) => {
  const token = await getValidAccessToken(user)
  const items = await fetchSpotifyPlaylists(token)

  // fetch already imported
  const { data: existing } = await supabase.from('playlists').select('spotify_playlist_id').eq('user_id', user.id)
  const existingIds = existing ? existing.map(e => e.spotify_playlist_id) : []

  return items.map(item => ({
    id: item.id,
    name: item.name,
    track_count: item.tracks.total,
    is_public: item.public,
    cover_image_url: item.images && item.images.length > 0 ? item.images[0].url : null,
    is_imported: existingIds.includes(item.id)
  }))
}
