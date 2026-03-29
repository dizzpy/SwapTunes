import { Router } from 'express'
import * as conversationsController from './conversations.controller.js'
import { requireAuth } from '../../shared/middleware/auth.js'

const router = Router()

router.get('/', requireAuth, conversationsController.getConversations)
router.post('/', requireAuth, conversationsController.startConversation)

router.get('/:conversationId/messages', requireAuth, conversationsController.getMessages)
router.post('/:conversationId/messages', requireAuth, conversationsController.sendMessage)
router.patch('/:conversationId/read', requireAuth, conversationsController.markMessagesRead)
router.delete('/:conversationId/messages/:messageId', requireAuth, conversationsController.deleteMessage)
router.delete('/:conversationId', requireAuth, conversationsController.deleteConversation)

export default router
