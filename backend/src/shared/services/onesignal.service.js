import axios from 'axios'
import { logger } from '../utils/logger.js'

const ONESIGNAL_API_URL = 'https://onesignal.com/api/v1/notifications'

const notificationTitles = {
  like: (actor) => `${actor} liked your post`,
  comment: (actor) => `${actor} commented on your post`,
  follow: (actor) => `${actor} started following you`,
  message: (actor) => `${actor} sent you a message`,
  collab: (actor) => `${actor} is interested in your collab`
}

class OneSignalService {
  /**
   * Sends a push notification to a user via OneSignal External User ID.
   *
   * This is fire-and-forget: failures are logged but never thrown,
   * so a push failure never breaks the in-app notification write.
   *
   * @param {string} userId      - Supabase user UUID (used as OneSignal External User ID)
   * @param {string} type        - Notification type: like | comment | follow | message | collab
   * @param {string} actorName   - Display name of the actor (e.g. "@username")
   * @param {string} [referenceId] - ID of the related resource (post, conversation, etc.)
   */
  async sendPushNotification(userId, { type, actorName, referenceId }) {
    const appId = process.env.ONESIGNAL_APP_ID
    const apiKey = process.env.ONESIGNAL_REST_API_KEY

    if (!appId || !apiKey) {
      logger.warn('OneSignal env vars not set — skipping push notification')
      return
    }

    const titleFn = notificationTitles[type]
    if (!titleFn) return

    const body = titleFn(actorName)

    try {
      await axios.post(
        ONESIGNAL_API_URL,
        {
          app_id: appId,
          target_channel: 'push',
          include_aliases: { external_id: [userId] },
          headings: { en: 'SwapTunes' },
          contents: { en: body },
          data: { type, reference_id: referenceId ?? null }
        },
        {
          headers: {
            Authorization: `Key ${apiKey}`,
            'Content-Type': 'application/json'
          }
        }
      )
    } catch (err) {
      logger.error({ err: err?.response?.data ?? err.message, userId, type }, 'OneSignal push failed')
    }
  }
}

export const oneSignalService = new OneSignalService()
