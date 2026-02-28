import { supabase } from '../config/supabase.js'
import { InternalError } from '../utils/errors.js'

export const notificationsRepository = {
  createNotification: async ({ userId, actorId, type, referenceId }) => {
    const { error } = await supabase.from('notifications').insert({
      user_id: userId,
      actor_id: actorId,
      type,
      reference_id: referenceId
    })

    if (error) {
      throw new InternalError('Failed to create notification')
    }
    return true
  }
}
