import { supabase } from '../../config/supabase.js'

// Setup creator profile service method interacting with the database.
// Handles both first-time setup and re-activation (user was creator before).
export const setupCreatorProfile = async (userId, data) => {
  // Check if a creator_profiles row already exists (re-activation case)
  const { data: existing } = await supabase
    .from('creator_profiles')
    .select('user_id')
    .eq('user_id', userId)
    .maybeSingle()

  if (existing) {
    // Re-activation: update existing profile + flip user_type back to creator
    const { data: profile, error } = await supabase
      .from('creator_profiles')
      .update({
        role_title: data.role_title,
        location: data.location ?? null,
        specializations: data.specializations,
        soundcloud_url: data.soundcloud_url ?? null,
        youtube_url: data.youtube_url ?? null,
        spotify_artist_url: data.spotify_artist_url ?? null,
        apple_music_url: data.apple_music_url ?? null,
        portfolio_url: data.portfolio_url ?? null
      })
      .eq('user_id', userId)
      .select()
      .single()

    if (error) throw { statusCode: 400, code: 'CREATOR_SETUP_FAILED', message: error.message }

    await supabase.from('users').update({ user_type: 'creator' }).eq('id', userId)

    return profile
  }

  // First-time setup: insert new creator_profiles row
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

// Deactivate creator — switches user_type back to listener and closes open collabs.
// The creator_profiles row is KEPT so data is preserved for re-activation.
export const deactivateCreator = async (userId) => {
  // Close all open collaborations for this creator
  await supabase.from('collaborations').update({ status: 'closed' }).eq('creator_id', userId).eq('status', 'open')

  // Flip user_type back to listener
  const { error } = await supabase.from('users').update({ user_type: 'listener' }).eq('id', userId)

  if (error) throw { statusCode: 400, code: 'DEACTIVATION_FAILED', message: error.message }
}
