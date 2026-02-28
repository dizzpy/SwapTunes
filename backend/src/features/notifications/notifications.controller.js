import * as notificationsService from './notifications.service.js'
import { success } from '../../shared/utils/response.js'

// Get notifications controller handler.
export const getNotifications = async (req, res, next) => {
  try {
    const notifs = await notificationsService.getNotifications(req.user.id, req.query)
    success(res, notifs)
  } catch (err) {
    next(err)
  }
}

// Mark as read controller handler.
export const markAsRead = async (req, res, next) => {
  try {
    const result = await notificationsService.markAsRead(req.user.id, req.params.notificationId)
    success(res, result)
  } catch (err) {
    next(err)
  }
}

// Mark all as read controller handler.
export const markAllAsRead = async (req, res, next) => {
  try {
    const result = await notificationsService.markAllAsRead(req.user.id)
    success(res, result)
  } catch (err) {
    next(err)
  }
}
