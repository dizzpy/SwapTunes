import { supabase } from '../config/supabase.js'
import { getPagination } from '../utils/pagination.js'

// We already have createNotification in this file
export const createNotification = async ({ userId, actorId, type, referenceId }) => {
  if (userId === actorId) return; // Don't notify yourself
  const { error } = await supabase.from('notifications').insert({ user_id: userId, actor_id: actorId, type, reference_id: referenceId })
  if (error) console.error("Failed to create notification:", error)
}

export const getNotifications = async (userId, query) => {
  const { from, to } = getPagination(query.page, query.limit)
  
  const { data, error } = await supabase
    .from('notifications')
    .select('*, actor:users!notifications_actor_id_fkey(id, username, full_name, avatar_url)')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .range(from, to)

  if (error) throw { statusCode: 400, code: 'FETCH_NOTIFS_FAILED', message: error.message }
  return data
}

export const markAsRead = async (userId, notificationId) => {
  const { error } = await supabase.from('notifications').update({ is_read: true }).match({ id: notificationId, user_id: userId })
  if (error) throw { statusCode: 400, code: 'MARK_READ_FAILED', message: error.message }
  return { success: true }
}

export const markAllAsRead = async (userId) => {
  const { error } = await supabase.from('notifications').update({ is_read: true }).eq('user_id', userId)
  if (error) throw { statusCode: 400, code: 'MARK_ALL_READ_FAILED', message: error.message }
  return { success: true }
}
