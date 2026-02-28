import { z } from 'zod'

export const creatorSetupSchema = z.object({
  role_title: z.string().min(1, "Role title is required"),
  location: z.string().optional(),
  specializations: z.array(z.string()).min(1, "Must select at least 1 specialization"),
  soundcloud_url: z.string().url().optional(),
  youtube_url: z.string().url().optional(),
  spotify_artist_url: z.string().url().optional(),
  apple_music_url: z.string().url().optional(),
  portfolio_url: z.string().url().optional(),
})
