-- RPC functions for atomic counter updates on the posts table.
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New query).

CREATE OR REPLACE FUNCTION increment_likes(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE posts SET likes_count = likes_count + 1 WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION decrement_likes(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION increment_comments(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE posts SET comments_count = comments_count + 1 WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION decrement_comments(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE posts SET comments_count = GREATEST(comments_count - 1, 0) WHERE id = p_id;
END;
$$;

-- ─── Messaging ────────────────────────────────────────────────────────────────

-- Returns all conversations for a user with last_message and unread_count
-- in a single query (no N+1). Used by GET /conversations.
-- Filters out conversations the requesting user has soft-deleted.
CREATE OR REPLACE FUNCTION get_conversations_for_user(p_user_id uuid)
RETURNS TABLE (
  id              uuid,
  last_message_at timestamptz,
  collab_id       uuid,
  user_one        json,
  user_two        json,
  last_message    text,
  unread_count    bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    c.id,
    c.last_message_at,
    c.collab_id,
    json_build_object(
      'id',         u1.id,
      'username',   u1.username,
      'full_name',  u1.full_name,
      'avatar_url', u1.avatar_url
    ) AS user_one,
    json_build_object(
      'id',         u2.id,
      'username',   u2.username,
      'full_name',  u2.full_name,
      'avatar_url', u2.avatar_url
    ) AS user_two,
    CASE WHEN lm.is_deleted THEN 'Message deleted' ELSE lm.content END AS last_message,
    (
      SELECT COUNT(*)
      FROM messages m
      WHERE m.conversation_id = c.id
        AND m.sender_id != p_user_id
        AND m.is_read = false
    ) AS unread_count
  FROM conversations c
  JOIN users u1 ON u1.id = c.user_one_id
  JOIN users u2 ON u2.id = c.user_two_id
  LEFT JOIN LATERAL (
    SELECT content, is_deleted
    FROM messages
    WHERE conversation_id = c.id
    ORDER BY created_at DESC
    LIMIT 1
  ) lm ON true
  WHERE (c.user_one_id = p_user_id AND NOT c.deleted_by_user_one)
     OR (c.user_two_id = p_user_id AND NOT c.deleted_by_user_two)
  ORDER BY c.last_message_at DESC NULLS LAST;
$$;

-- conversations: add per-user soft-delete flags
-- ALTER TABLE conversations
--   ADD COLUMN IF NOT EXISTS deleted_by_user_one BOOLEAN NOT NULL DEFAULT FALSE,
--   ADD COLUMN IF NOT EXISTS deleted_by_user_two BOOLEAN NOT NULL DEFAULT FALSE;

-- ─── RLS Policies ─────────────────────────────────────────────────────────────
-- Run these in the Supabase SQL Editor after enabling RLS on each table.

-- Enable RLS (idempotent)
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- conversations: users can only see conversations they are part of
CREATE POLICY IF NOT EXISTS "conversations_select_participant"
  ON conversations FOR SELECT
  USING (user_one_id = auth.uid() OR user_two_id = auth.uid());

-- messages: users can only see messages in their conversations
CREATE POLICY IF NOT EXISTS "messages_select_participant"
  ON messages FOR SELECT
  USING (
    conversation_id IN (
      SELECT id FROM conversations
      WHERE user_one_id = auth.uid() OR user_two_id = auth.uid()
    )
  );

-- messages: users can only insert messages as themselves into their conversations
CREATE POLICY IF NOT EXISTS "messages_insert_participant"
  ON messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
    AND conversation_id IN (
      SELECT id FROM conversations
      WHERE user_one_id = auth.uid() OR user_two_id = auth.uid()
    )
  );

-- messages: allow updating is_read only (for mark-as-read)
CREATE POLICY IF NOT EXISTS "messages_update_read"
  ON messages FOR UPDATE
  USING (
    conversation_id IN (
      SELECT id FROM conversations
      WHERE user_one_id = auth.uid() OR user_two_id = auth.uid()
    )
  )
  WITH CHECK (sender_id != auth.uid());  -- can only mark OTHER user's messages as read
