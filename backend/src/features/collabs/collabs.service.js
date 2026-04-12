import { supabase } from '../../config/supabase.js'
import { getPagination } from '../../shared/utils/pagination.js'
import { matchCreatorsForCollab } from '../../shared/services/ai.service.js'

// Create collab service method interacting with the database.
export const createCollab = async (creatorId, data) => {
  const { data: collab, error } = await supabase
    .from('collaborations')
    .insert([
      {
        creator_id: creatorId,
        title: data.title,
        description: data.description,
        looking_for: data.looking_for,
        genre_style: data.genre_style,
        payment_type: data.payment_type
      }
    ])
    .select('*, creator:users(id, username, full_name, avatar_url, is_verified)')
    .single()

  if (error) throw { statusCode: 400, code: 'CREATE_COLLAB_FAILED', message: error.message }
  return collab
}

// Get collabs service method interacting with the database.
export const getCollabs = async (query) => {
  const { from, to } = getPagination(query.page, query.limit)

  let qb = supabase
    .from('collaborations')
    .select('*, creator:users(id, username, full_name, avatar_url, is_verified)')
    .eq('status', 'open')
    .order('created_at', { ascending: false })

  if (query.role) {
    qb = qb.contains('looking_for', [query.role])
  }

  const { data, error } = await qb.range(from, to)

  if (error) throw { statusCode: 400, code: 'FETCH_COLLABS_FAILED', message: error.message }
  return data
}

// Get collab by id service method interacting with the database.
export const getCollabById = async (collabId) => {
  const { data, error } = await supabase
    .from('collaborations')
    .select('*, creator:users(id, username, full_name, avatar_url, is_verified)')
    .eq('id', collabId)
    .single()

  if (error || !data) throw { statusCode: 404, code: 'NOT_FOUND', message: 'Collaboration not found' }
  return data
}

// Update collab service method interacting with the database.
export const updateCollab = async (creatorId, collabId, updateData) => {
  const { data, error } = await supabase
    .from('collaborations')
    .update(updateData)
    .match({ id: collabId, creator_id: creatorId })
    .select()
    .single()

  if (error) throw { statusCode: 400, code: 'UPDATE_COLLAB_FAILED', message: error.message }
  return data
}

// Delete collab service method interacting with the database.
export const deleteCollab = async (creatorId, collabId) => {
  const { error } = await supabase.from('collaborations').delete().match({ id: collabId, creator_id: creatorId })

  if (error) throw { statusCode: 400, code: 'DELETE_COLLAB_FAILED', message: error.message }
  return { success: true }
}

// Get my collabs service method interacting with the database.
export const getMyCollabs = async (creatorId, query) => {
  const { from, to } = getPagination(query.page, query.limit)

  const { data, error } = await supabase
    .from('collaborations')
    .select('*, creator:users(id, username, full_name, avatar_url, is_verified)')
    .eq('creator_id', creatorId)
    .order('created_at', { ascending: false })
    .range(from, to)

  if (error) throw { statusCode: 400, code: 'FETCH_MY_COLLABS_FAILED', message: error.message }
  return data
}

// Fetch all active creators except the requesting user for AI matching.
export const getCreatorsForMatching = async (excludeUserId) => {
  const { data, error } = await supabase
    .from('creator_profiles')
    .select(`
      user_id,
      role_title,
      specializations,
      users (
        username,
        avatar_url,
        user_type
      )
    `)
    .neq('user_id', excludeUserId)

  if (error) throw { statusCode: 400, code: 'FETCH_CREATORS_FAILED', message: error.message }
  return (data ?? []).filter((c) => c.users?.user_type === 'creator')
}

// Find the top matching creators for a collab listing using AI.
export const findCollabMatches = async (collabId, requestingUserId) => {
  const collab = await getCollabById(collabId)

  if (collab.creator_id !== requestingUserId) {
    throw { statusCode: 403, code: 'FORBIDDEN', message: 'You can only match on your own collab listings' }
  }

  const creators = await getCreatorsForMatching(requestingUserId)
  if (!creators.length) return []

  const aiResult = await matchCreatorsForCollab(collab, creators)

  const enriched = aiResult.matches
    .map((match) => {
      const creator = creators.find((c) => c.user_id === match.userId)
      return {
        userId: match.userId,
        matchScore: match.matchScore,
        reason: match.reason,
        profile: creator ?? null,
      }
    })
    .filter((m) => m.profile !== null)

  return enriched
}

// Get collabs by user id (public profile view).
export const getUserCollabs = async (userId, query) => {
  const { from, to } = getPagination(query.page, query.limit)

  const { data, error } = await supabase
    .from('collaborations')
    .select('*, creator:users(id, username, full_name, avatar_url, is_verified)')
    .eq('creator_id', userId)
    .eq('status', 'open')
    .order('created_at', { ascending: false })
    .range(from, to)

  if (error) throw { statusCode: 400, code: 'FETCH_USER_COLLABS_FAILED', message: error.message }
  return data
}
