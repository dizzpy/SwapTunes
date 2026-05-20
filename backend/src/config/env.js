import { z } from 'zod'
import dotenv from 'dotenv'
import { logger } from '../shared/utils/logger.js'

// Load environment variables from .env file
dotenv.config()

const envSchema = z.object({
  PORT: z.string().default('3000'),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  SUPABASE_URL: z.string().url('Must be a valid Supabase URL'),
  SUPABASE_ANON_KEY: z.string().min(10, 'Supabase Anon Key is required'),
  // Mark optional keys for now, they can be made required later as integration deepens
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional(),
  SPOTIFY_CLIENT_ID: z.string().optional(),
  SPOTIFY_CLIENT_SECRET: z.string().optional(),
  SPOTIFY_REDIRECT_URI: z.string().optional(),
  GEMINI_API_KEY: z.string().optional(),
  GEMINI_API_KEY_BACKUP_ONE: z.string().optional()
})

const parseEnvVars = () => {
  const parsedValue = envSchema.safeParse(process.env)

  if (!parsedValue.success) {
    logger.fatal({ err: parsedValue.error.format() }, 'Environment variable validation failed')
    process.exit(1)
  }

  return parsedValue.data
}

export const env = parseEnvVars()
