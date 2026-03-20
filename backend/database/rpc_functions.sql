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
