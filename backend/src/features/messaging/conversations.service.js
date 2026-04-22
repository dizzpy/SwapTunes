import { supabase } from '../../config/supabase.js'
import { notificationsService } from '../notifications/notifications.service.js'

// Get conversations service method interacting with the database.
// Uses the get_conversations_for_user RPC to fetch last_message and
// unread_count in a single JOIN query (avoids N+1).
export const getConversations = async (userId) => {
  const { data, error } = await supabase.rpc('get_conversations_for_user', {
    p_user_id: userId
  })

  if (error) throw { statusCode: 400, code: 'FETCH_CONVOS_FAILED', message: error.message }
  return data
}

// Send message service method interacting with the database.
export const sendMessage = async (userId, conversationId, content) => {
  if (!content || content.trim().length === 0) {
    throw { statusCode: 400, code: 'INVALID', message: 'Message content cannot be empty' }
  }
  if (content.length > 2000) {
    throw { statusCode: 400, code: 'INVALID', message: 'Message content exceeds 2000 characters' }
  }

  const { data: convo, error: convoError } = await supabase
    .from('conversations')
    .select('*')
    .eq('id', conversationId)
    .single()
  if (convoError || !convo) {
    throw { statusCode: 404, code: 'NOT_FOUND', message: 'Conversation not found' }
  }
  if (convo.user_one_id !== userId && convo.user_two_id !== userId) {
    throw { statusCode: 403, code: 'FORBIDDEN', message: 'Not a participant of this conversation' }
  }

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
// Supports cursor-based pagination via `before` (ISO timestamp) to avoid
// duplicates/skips when real-time inserts shift page boundaries.
export const getMessages = async (userId, conversationId, query) => {
  const limit = Math.min(parseInt(query.limit ?? '30', 10), 100)
  const before = query.before // ISO timestamp cursor, optional

  // Verify participant
  const { data: convo } = await supabase.from('conversations').select('*').eq('id', conversationId).single()
  if (!convo || (convo.user_one_id !== userId && convo.user_two_id !== userId)) {
    throw { statusCode: 403, code: 'FORBIDDEN', message: 'Not a participant of this conversation' }
  }

  let q = supabase
    .from('messages')
    .select('*')
    .eq('conversation_id', conversationId)
    .order('created_at', { ascending: false })
    .limit(limit)

  if (before) {
    q = q.lt('created_at', before)
  }

  const { data: messages, error } = await q
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

// Delete conversation service method interacting with the database.
// Soft-deletes for the requesting user only. Both users must delete before
// data is permanently removed, so the other participant is unaffected.
export const deleteConversation = async (userId, conversationId) => {
  const { data: convo } = await supabase.from('conversations').select('*').eq('id', conversationId).single()
  if (!convo || (convo.user_one_id !== userId && convo.user_two_id !== userId)) {
    throw { statusCode: 403, code: 'FORBIDDEN', message: 'Not a participant of this conversation' }
  }

  const isUserOne = convo.user_one_id === userId
  const flagField = isUserOne ? 'deleted_by_user_one' : 'deleted_by_user_two'

  const { data: updated, error } = await supabase
    .from('conversations')
    .update({ [flagField]: true })
    .eq('id', conversationId)
    .select('deleted_by_user_one, deleted_by_user_two')
    .single()

  if (error) throw { statusCode: 400, code: 'DELETE_CONVO_FAILED', message: error.message }

  // Permanently delete only when both users have removed the conversation
  if (updated.deleted_by_user_one && updated.deleted_by_user_two) {
    await supabase.from('messages').delete().eq('conversation_id', conversationId)
    await supabase.from('conversations').delete().eq('id', conversationId)
  }

  return { success: true }
}

// Delete a single message service method interacting with the database.
// Only the sender can delete. Sets is_deleted = true so the other participant
// still sees a "This message was deleted" placeholder.
export const deleteMessage = async (userId, conversationId, messageId) => {
  const { data: msg } = await supabase
    .from('messages')
    .select('sender_id, conversation_id')
    .eq('id', messageId)
    .single()

  if (!msg || msg.conversation_id !== conversationId) {
    throw { statusCode: 404, code: 'NOT_FOUND', message: 'Message not found' }
  }
  if (msg.sender_id !== userId) {
    throw { statusCode: 403, code: 'FORBIDDEN', message: 'You can only delete your own messages' }
  }

  const { error } = await supabase.from('messages').update({ is_deleted: true }).eq('id', messageId)

  if (error) throw { statusCode: 400, code: 'DELETE_MSG_FAILED', message: error.message }
  return { success: true }
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
