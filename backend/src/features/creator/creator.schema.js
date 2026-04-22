import { z } from 'zod'

export const creatorSetupSchema = z.object({
  role_title: z.string().min(1, 'Role title is required'),
  location: z.string().optional(),
  specializations: z.array(z.string()).min(1, 'Must select at least 1 specialization'),
  soundcloud_url: z.string().url().optional(),
  youtube_url: z.string().url().optional(),
  spotify_artist_url: z.string().url().optional(),
  apple_music_url: z.string().url().optional(),
  portfolio_url: z.string().url().optional()
})

export const songBuilderSchema = z.object({
  idea: z.string().min(5, 'Please describe your idea').max(300),
  genre: z.string().min(1, 'Genre is required'),
  lyrics: z.string().max(500).optional(),
  type: z.enum(['vocal', 'instrumental'], {
    required_error: 'Please select vocal or instrumental'
  })
})

export const saveSongPlanSchema = z.object({
  title: z.string().min(1, 'Title is required'),
  data: z.any()
})
