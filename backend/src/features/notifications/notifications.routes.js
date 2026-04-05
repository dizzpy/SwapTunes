import { Router } from 'express'
import * as notificationsController from './notifications.controller.js'
import { requireAuth } from '../../shared/middleware/auth.js'

const router = Router()

router.get('/', requireAuth, notificationsController.getNotifications)
router.patch('/read-all', requireAuth, notificationsController.markAllAsRead)
router.patch('/:notificationId/read', requireAuth, notificationsController.markAsRead)
router.delete('/:notificationId', requireAuth, notificationsController.deleteNotification)

export default router
