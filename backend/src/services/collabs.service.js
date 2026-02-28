import { supabase } from '../config/supabase.js'
import { getPagination } from '../utils/pagination.js'

export const createCollab = async (creatorId, data) => {
  const { data: collab, error } = await supabase
    .from('collaborations')
    .insert([{
      creator_id: creatorId,
      title: data.title,
      description: data.description,
      looking_for: data.looking_for,
      genre_style: data.genre_style,
      payment_type: data.payment_type
    }])
    .select('*, creator:users(id, username, full_name, avatar_url, is_verified)')
    .single()

  if (error) throw { statusCode: 400, code: 'CREATE_COLLAB_FAILED', message: error.message }
  return collab
}

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

export const getCollabById = async (collabId) => {
  const { data, error } = await supabase
    .from('collaborations')
    .select('*, creator:users(id, username, full_name, avatar_url, is_verified)')
    .eq('id', collabId)
    .single()

  if (error || !data) throw { statusCode: 404, code: 'NOT_FOUND', message: 'Collaboration not found' }
  return data
}

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

export const deleteCollab = async (creatorId, collabId) => {
  const { error } = await supabase
    .from('collaborations')
    .delete()
    .match({ id: collabId, creator_id: creatorId })

  if (error) throw { statusCode: 400, code: 'DELETE_COLLAB_FAILED', message: error.message }
  return { success: true }
}
