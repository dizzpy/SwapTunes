const uid = () => Math.random().toString(36).slice(2, 9)

export const fixtures = {
  user: (o = {}) => ({
    id: `user-${uid()}`,
    username: 'testuser',
    full_name: 'Test User',
    user_type: 'listener',
    created_at: new Date().toISOString(),
    ...o
  }),

  creator: (o = {}) => ({
    id: `user-${uid()}`,
    username: 'creator1',
    user_type: 'creator',
    bio: 'I make music',
    genres: ['rock'],
    created_at: new Date().toISOString(),
    ...o
  }),

  post: (o = {}) => ({
    id: `post-${uid()}`,
    user_id: 'user-123',
    content: 'Test post',
    likes_count: 0,
    comments_count: 0,
    created_at: new Date().toISOString(),
    ...o
  }),

  message: (o = {}) => ({
    id: `msg-${uid()}`,
    conversation_id: 'conv-123',
    sender_id: 'user-123',
    content: 'Test message',
    created_at: new Date().toISOString(),
    is_read: false,
    ...o
  }),

  conversation: (o = {}) => ({
    id: `conv-${uid()}`,
    user_one_id: 'user-123',
    user_two_id: 'user-456',
    created_at: new Date().toISOString(),
    ...o
  })
}
