import { supabase } from '../config/supabase.js'

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
