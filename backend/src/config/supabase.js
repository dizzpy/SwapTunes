import { createClient } from '@supabase/supabase-js'
import { env } from './env.js'
import { logger } from '../shared/utils/logger.js'

if (!env.SUPABASE_SERVICE_ROLE_KEY) {
  logger.warn('SUPABASE_SERVICE_ROLE_KEY is not defined in .env! Backend operations bypassing RLS might fail.')
}

export const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
})
