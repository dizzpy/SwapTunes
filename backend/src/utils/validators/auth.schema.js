import { z } from 'zod'

export const profileSetupSchema = z.object({
  full_name: z.string().min(1, "Full name is required"),
  username: z.string().min(3, "Username must be at least 3 characters").regex(/^[a-zA-Z0-9_]+$/, "Username can only contain letters, numbers, and underscores"),
  bio: z.string().optional(),
  avatar_url: z.string().optional(),
  genres: z.array(z.string()).min(3, "Must select at least 3 genres")
})

export const spotifyConnectSchema = z.object({
  code: z.string().min(1, "Auth code is required"),
  redirect_uri: z.string().min(1, "Redirect URI is required")
})
