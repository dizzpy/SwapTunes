import { emitter } from '../emitter.js'
import { logger } from '../../utils/logger.js'

import { notificationsRepository } from '../../../features/notifications/notifications.repository.js'

// Listen for a post being liked
emitter.on('post.liked', async ({ postId, actorId, postOwnerId }) => {
  try {
    if (actorId === postOwnerId) return // Don't notify if liking own post

    await notificationsRepository.createNotification({
      userId: postOwnerId,
      actorId: actorId,
      type: 'like',
      referenceId: postId
    })
  } catch (error) {
    logger.error({ err: error, event: 'post.liked' }, 'Failed to create notification')
  }
})

// Listen for comments
emitter.on('post.commented', async ({ postId, actorId, postOwnerId }) => {
  try {
    if (actorId === postOwnerId) return

    await notificationsRepository.createNotification({
      userId: postOwnerId,
      actorId: actorId,
      type: 'comment',
      referenceId: postId
    })
  } catch (error) {
    logger.error({ err: error, event: 'post.commented' }, 'Failed to create notification')
  }
})

// Add other notification listeners (follow, collab, message) here
