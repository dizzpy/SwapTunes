import { supabase } from '../../config/supabase.js'

// Setup creator profile service method interacting with the database.
export const setupCreatorProfile = async (userId, data) => {
  // Add to creator_profiles
  const { data: profile, error } = await supabase
    .from('creator_profiles')
    .insert([
      {
        user_id: userId,
        role_title: data.role_title,
        location: data.location,
        specializations: data.specializations,
        soundcloud_url: data.soundcloud_url,
        youtube_url: data.youtube_url,
        spotify_artist_url: data.spotify_artist_url,
        apple_music_url: data.apple_music_url,
        portfolio_url: data.portfolio_url
      }
    ])
    .select()
    .single()

  if (error) {
    if (error.code === '23505') throw { statusCode: 400, code: 'ALREADY_CREATOR', message: 'User is already a creator' }
    throw { statusCode: 400, code: 'CREATOR_SETUP_FAILED', message: error.message }
  }

  // Update users.user_type to 'creator'
  await supabase.from('users').update({ user_type: 'creator' }).eq('id', userId)

  return profile
}

// Update creator profile service method interacting with the database.
export const updateCreatorProfile = async (userId, data) => {
  const { data: profile, error } = await supabase
    .from('creator_profiles')
    .update(data)
    .eq('user_id', userId)
    .select()
    .single()

  if (error) {
    if (error.code === 'PGRST116') throw { statusCode: 404, code: 'NOT_CREATOR', message: 'You are not a creator' }
    throw { statusCode: 400, code: 'UPDATE_FAILED', message: error.message }
  }

  return profile
}
