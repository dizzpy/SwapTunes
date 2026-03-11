import { supabase } from '../../config/supabase.js'
import { notificationsService } from '../notifications/notifications.service.js'
import { getPagination } from '../../shared/utils/pagination.js'

// Get conversations service method interacting with the database.
export const getConversations = async (userId, query) => {
  const { from, to } = getPagination(query.page, query.limit)

  // A user is either user_one or user_two
  const { data, error } = await supabase
    .from('conversations')
    .select(
      `
      id,
      last_message_at,
      collab_id,
      user_one:users!conversations_user_one_id_fkey(id, username, full_name, avatar_url),
      user_two:users!conversations_user_two_id_fkey(id, username, full_name, avatar_url)
    `
    )
    .or(`user_one_id.eq.${userId},user_two_id.eq.${userId}`)
    .order('last_message_at', { ascending: false, nullsFirst: false })
    .range(from, to)

  if (error) throw { statusCode: 400, code: 'FETCH_CONVOS_FAILED', message: error.message }
  return data
}

// Send message service method interacting with the database.
export const sendMessage = async (userId, conversationId, content) => {
  // Insert message
  const { data: message, error } = await supabase
    .from('messages')
    .insert([{ conversation_id: conversationId, sender_id: userId, content }])
    .select()
    .single()

  if (error) throw { statusCode: 400, code: 'SEND_MSG_FAILED', message: error.message }

  // Update conversation last_message_at
  await supabase.from('conversations').update({ last_message_at: new Date().toISOString() }).eq('id', conversationId)

  // Notify other user
  const { data: convo } = await supabase.from('conversations').select('*').eq('id', conversationId).single()
  if (convo) {
    const otherId = convo.user_one_id === userId ? convo.user_two_id : convo.user_one_id
    await notificationsService.createNotification({
      userId: otherId,
      actorId: userId,
      type: 'message',
      referenceId: conversationId
    })
  }

  return message
}

// Get messages service method interacting with the database.
export const getMessages = async (userId, conversationId, query) => {
  const { from, to } = getPagination(query.page, query.limit)

  // Verify participant
  const { data: convo } = await supabase.from('conversations').select('*').eq('id', conversationId).single()
  if (!convo || (convo.user_one_id !== userId && convo.user_two_id !== userId)) {
    throw { statusCode: 403, code: 'FORBIDDEN', message: 'Not a participant of this conversation' }
  }

  const { data: messages, error } = await supabase
    .from('messages')
    .select('*')
    .eq('conversation_id', conversationId)
    .order('created_at', { ascending: false }) // typically paginated backwards then reversed client side
    .range(from, to)

  if (error) throw { statusCode: 400, code: 'FETCH_MSGS_FAILED', message: error.message }
  return messages
}

// Start conversation service method interacting with the database.
export const startConversation = async (userId, recipientId, collabId = null) => {
  if (userId === recipientId) throw { statusCode: 400, code: 'INVALID', message: 'Cannot chat with yourself' }

  const u1 = userId < recipientId ? userId : recipientId
  const u2 = userId < recipientId ? recipientId : userId

  const { data: existing } = await supabase
    .from('conversations')
    .select('*')
    .eq('user_one_id', u1)
    .eq('user_two_id', u2)
    .single()

  if (existing) return existing

  const { data, error } = await supabase
    .from('conversations')
    .insert([{ user_one_id: u1, user_two_id: u2, collab_id: collabId }])
    .select()
    .single()

  if (error) throw { statusCode: 400, code: 'START_CONVO_FAILED', message: error.message }
  return data
}

// Mark messages read service method interacting with the database.
export const markMessagesRead = async (userId, conversationId) => {
  // Verify participant
  const { data: convo } = await supabase.from('conversations').select('*').eq('id', conversationId).single()
  if (!convo || (convo.user_one_id !== userId && convo.user_two_id !== userId)) {
    throw { statusCode: 403, code: 'FORBIDDEN', message: 'Not a participant of this conversation' }
  }

  // Update messages sent by the *other* user in this conversation to read = true
  const { error } = await supabase
    .from('messages')
    .update({ is_read: true })
    .match({ conversation_id: conversationId })
    .neq('sender_id', userId)

  if (error) throw { statusCode: 400, code: 'MARK_READ_FAILED', message: error.message }

  return { success: true }
}
