import * as conversationsService from './conversations.service.js'
import { success } from '../../shared/utils/response.js'

// Get conversations controller handler.
export const getConversations = async (req, res, next) => {
  try {
    const convos = await conversationsService.getConversations(req.user.id)
    success(res, convos)
  } catch (err) {
    next(err)
  }
}

// Get messages controller handler.
export const getMessages = async (req, res, next) => {
  try {
    const msgs = await conversationsService.getMessages(req.user.id, req.params.conversationId, req.query)
    success(res, msgs)
  } catch (err) {
    next(err)
  }
}

// Send message controller handler.
export const sendMessage = async (req, res, next) => {
  try {
    const msg = await conversationsService.sendMessage(req.user.id, req.params.conversationId, req.body.content)
    success(res, msg, 201)
  } catch (err) {
    next(err)
  }
}

// Start conversation controller handler.
export const startConversation = async (req, res, next) => {
  try {
    const convo = await conversationsService.startConversation(req.user.id, req.body.recipient_id, req.body.collab_id)
    success(res, convo, 201)
  } catch (err) {
    next(err)
  }
}

// Delete conversation controller handler.
export const deleteConversation = async (req, res, next) => {
  try {
    const result = await conversationsService.deleteConversation(req.user.id, req.params.conversationId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

// Delete single message controller handler.
export const deleteMessage = async (req, res, next) => {
  try {
    const result = await conversationsService.deleteMessage(
      req.user.id,
      req.params.conversationId,
      req.params.messageId
    )
    success(res, result)
  } catch (err) {
    next(err)
  }
}

// Mark messages read controller handler.
export const markMessagesRead = async (req, res, next) => {
  try {
    const result = await conversationsService.markMessagesRead(req.user.id, req.params.conversationId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}
