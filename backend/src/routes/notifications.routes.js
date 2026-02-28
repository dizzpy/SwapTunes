import { Router } from 'express'
import * as notificationsController from '../controllers/notifications.controller.js'
import { requireAuth } from '../middleware/auth.js'

const router = Router()

router.get('/', requireAuth, notificationsController.getNotifications)
router.patch('/read-all', requireAuth, notificationsController.markAllAsRead)
router.patch('/:notificationId/read', requireAuth, notificationsController.markAsRead)

export default router
