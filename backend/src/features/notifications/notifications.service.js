import { supabase } from '../../config/supabase.js'
import { getPagination } from '../../shared/utils/pagination.js'
import { oneSignalService } from '../../shared/services/onesignal.service.js'
import { notificationsRepository } from './notifications.repository.js'

class NotificationsService {
  constructor(repository) {
    this.repository = repository
  }

  async createNotification({ userId, actorId, type, referenceId }) {
    if (userId === actorId) return // Don't notify yourself

    // Write the in-app notification to the DB
    await this.repository.createNotification({ userId, actorId, type, referenceId })

    // Fire push notification — non-blocking, failures are logged not thrown
    this._sendPush(userId, actorId, type, referenceId)
  }

  async _sendPush(userId, actorId, type, referenceId) {
    try {
      const { data: actor } = await supabase
        .from('users')
        .select('username')
        .eq('id', actorId)
        .single()

      const actorName = actor?.username ? `@${actor.username}` : 'Someone'
      await oneSignalService.sendPushNotification(userId, { type, actorName, referenceId })
    } catch (_) {
      // Push failure must never surface to the caller
    }
  }

  async getNotifications(userId, query) {
    const { from, to } = getPagination(query.page, query.limit)

    // In a full OOP refactor, this query would also move into notificationsRepository
    const { data, error } = await supabase
      .from('notifications')
      .select('*, actor:users!notifications_actor_id_fkey(id, username, full_name, avatar_url)')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(from, to)

    if (error) throw { statusCode: 400, code: 'FETCH_NOTIFS_FAILED', message: error.message }
    return data
  }

  async markAsRead(userId, notificationId) {
    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .match({ id: notificationId, user_id: userId })
    if (error) throw { statusCode: 400, code: 'MARK_READ_FAILED', message: error.message }
    return { success: true }
  }

  async markAllAsRead(userId) {
    const { error } = await supabase.from('notifications').update({ is_read: true }).eq('user_id', userId)
    if (error) throw { statusCode: 400, code: 'MARK_ALL_READ_FAILED', message: error.message }
    return { success: true }
  }

  async deleteNotification(userId, notificationId) {
    const { error } = await supabase
      .from('notifications')
      .delete()
      .match({ id: notificationId, user_id: userId })
    if (error) throw { statusCode: 400, code: 'DELETE_NOTIF_FAILED', message: error.message }
    return { success: true }
  }
}

// Instantiate the service with Dependency Injection
export const notificationsService = new NotificationsService(notificationsRepository)
