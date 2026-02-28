import { z } from 'zod'

export const postSchema = z.object({
  content: z.string().min(1, "Post content is required").max(1000, "Max 1000 characters"),
  image_url: z.string().url().optional()
})

export const commentSchema = z.object({
  content: z.string().min(1, "Comment content cannot be empty").max(500, "Max 500 characters")
})

export const reportSchema = z.object({
  reason: z.string().min(1, "Report reason must be provided")
})
