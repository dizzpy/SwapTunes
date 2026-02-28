import * as conversationsService from '../services/conversations.service.js'
import { success } from '../utils/response.js'

export const getConversations = async (req, res, next) => {
  try {
     const convos = await conversationsService.getConversations(req.user.id, req.query)
     success(res, convos)
  } catch (err) { next(err) }
}

export const getMessages = async (req, res, next) => {
  try {
     const msgs = await conversationsService.getMessages(req.user.id, req.params.conversationId, req.query)
     success(res, msgs)
  } catch (err) { next(err) }
}

export const sendMessage = async (req, res, next) => {
  try {
     const msg = await conversationsService.sendMessage(req.user.id, req.params.conversationId, req.body.content)
     success(res, msg, 201)
  } catch (err) { next(err) }
}

export const startConversation = async (req, res, next) => {
  try {
     const convo = await conversationsService.startConversation(req.user.id, req.body.recipient_id, req.body.collab_id)
     success(res, convo, 201)
  } catch (err) { next(err) }
}
