import { z } from 'zod';
import dotenv from 'dotenv';

dotenv.config();

const envSchema = z.object({
  PORT: z.string().default('3000'),
  NODE_ENV: z.enum(['production', 'development', 'test']).default('development'),
  SUPABASE_URL: z.string().min(1, 'Supabase URL is required'),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1, 'Supabase Service Role Key is required'),
  SPOTIFY_CLIENT_ID: z.string().min(1, 'Spotify Client ID is required').optional(),
  SPOTIFY_CLIENT_SECRET: z.string().min(1, 'Spotify Client Secret is required').optional(),
});

const _env = envSchema.safeParse(process.env);

if (!_env.success) {
  console.warn(`Config validation error:`, _env.error.format());
}

export const config = _env.success ? {
  env: _env.data.NODE_ENV,
  port: parseInt(_env.data.PORT, 10),
  supabase: {
    url: _env.data.SUPABASE_URL,
    serviceRoleKey: _env.data.SUPABASE_SERVICE_ROLE_KEY,
  },
  spotify: {
    clientId: _env.data.SPOTIFY_CLIENT_ID,
    clientSecret: _env.data.SPOTIFY_CLIENT_SECRET,
  }
} : {};
