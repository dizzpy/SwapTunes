import { supabase } from '../../config/supabase.js'

/**
 * DEV ONLY — force-reset a user's role for testing purposes.
 *
 * role: 'listener' | 'creator'
 * clearCreatorProfile: if true, deletes the creator_profiles row too
 */
export const resetUserRole = async (username, role, clearCreatorProfile) => {
  const { data: user, error: userErr } = await supabase
    .from('users')
    .select('id')
    .eq('username', username)
    .single()

  if (userErr || !user) throw { statusCode: 404, code: 'NOT_FOUND', message: `User '${username}' not found` }

  const { error } = await supabase
    .from('users')
    .update({ user_type: role })
    .eq('id', user.id)

  if (error) throw { statusCode: 400, code: 'UPDATE_FAILED', message: error.message }

  if (clearCreatorProfile) {
    await supabase.from('creator_profiles').delete().eq('user_id', user.id)
  }

  return { username, role, creatorProfileCleared: clearCreatorProfile }
}
