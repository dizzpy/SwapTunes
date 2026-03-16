import { supabase } from '../../config/supabase.js'
import { getSpotifyTokens } from '../../shared/services/spotify.service.js'

// Setup profile service method interacting with the database.
export const setupProfile = async (userId, userEmail, profileData) => {
  // Check if setup already
  const { data: existingUser } = await supabase.from('users').select('id').eq('id', userId).single()

  if (existingUser) {
    throw { statusCode: 400, code: 'ALREADY_SETUP', message: 'Profile already setup' }
  }

  // Insert to users
  const { data: user, error: userError } = await supabase
    .from('users')
    .insert([
      {
        id: userId,
        email: userEmail,
        full_name: profileData.full_name,
        username: profileData.username,
        bio: profileData.bio,
        avatar_url: profileData.avatar_url,
        user_type: 'listener',
        spotify_connected: false
      }
    ])
    .select()
    .single()

  if (userError) throw { statusCode: 400, code: 'SETUP_FAILED', message: userError.message }

  // Insert genres
  const genresToInsert = profileData.genres.map((g) => ({ user_id: userId, genre: g }))
  const { error: genreError } = await supabase.from('user_genres').insert(genresToInsert)

  if (genreError) throw { statusCode: 400, code: 'GENRE_INSERT_FAILED', message: genreError.message }

  return user
}

// Connect spotify service method interacting with the database.
export const connectSpotify = async (userId, authCode, redirectUri) => {
  // get tokens
  const tokens = await getSpotifyTokens(authCode, redirectUri)

  if (!tokens.access_token) {
    throw { statusCode: 400, code: 'SPOTIFY_CONN_FAILED', message: 'Could not get access token' }
  }

  const { data, error } = await supabase
    .from('users')
    .update({
      spotify_connected: true,
      spotify_access_token: tokens.access_token,
      spotify_refresh_token: tokens.refresh_token
    })
    .eq('id', userId)
    .select()
    .single()

  if (error) throw { statusCode: 400, code: 'SPOTIFY_UPDATE_FAILED', message: error.message }
  return data
}
