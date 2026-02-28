import { supabase } from '../config/supabase.js'
import { InternalError } from '../utils/errors.js'

export const postsRepository = {
  addLike: async (postId, userId) => {
    const { error } = await supabase.from('post_likes').insert({ post_id: postId, user_id: userId })
    if (error) {
      if (error.code === '23505') return false // Duplicate like logic
      throw new InternalError('Failed to like post')
    }
    return true
  }
}
