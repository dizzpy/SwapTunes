import { supabase } from '../../config/supabase.js'
import { env } from '../../config/env.js'

const startTime = Date.now()

/**
 * GET /api/v1/health
 * Lightweight liveness check — confirms the server is running.
 */
export const getLiveness = (_req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString()
  })
}

/**
 * GET /api/v1/health/detailed
 * Readiness check — confirms the server and its dependencies are healthy.
 */
export const getDetailedHealth = async (_req, res) => {
  const checks = await Promise.allSettled([checkSupabase(), checkSpotify()])

  const [supabaseResult, spotifyResult] = checks

  const services = {
    supabase: formatResult(supabaseResult),
    spotify: formatResult(spotifyResult)
  }

  const allHealthy = Object.values(services).every((s) => s.status === 'ok')

  const memoryUsage = process.memoryUsage()

  const payload = {
    status: allHealthy ? 'ok' : 'degraded',
    timestamp: new Date().toISOString(),
    uptime: formatUptime(Date.now() - startTime),
    environment: env.NODE_ENV,
    version: process.env.npm_package_version ?? 'unknown',
    node: process.version,
    memory: {
      heapUsed: formatBytes(memoryUsage.heapUsed),
      heapTotal: formatBytes(memoryUsage.heapTotal),
      rss: formatBytes(memoryUsage.rss)
    },
    services
  }

  res.status(allHealthy ? 200 : 503).json(payload)
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function checkSupabase() {
  const start = Date.now()
  const { error } = await supabase.from('users').select('id').limit(1)
  if (error) throw new Error(error.message)
  return { latencyMs: Date.now() - start }
}

async function checkSpotify() {
  const configured = !!(env.SPOTIFY_CLIENT_ID && env.SPOTIFY_CLIENT_SECRET)
  if (!configured) throw new Error('Spotify credentials not configured')
  return { configured: true }
}

function formatResult(settled) {
  if (settled.status === 'fulfilled') {
    return { status: 'ok', ...settled.value }
  }
  return { status: 'error', message: settled.reason?.message ?? 'Unknown error' }
}

function formatBytes(bytes) {
  const mb = bytes / 1024 / 1024
  return `${mb.toFixed(2)} MB`
}

function formatUptime(ms) {
  const totalSeconds = Math.floor(ms / 1000)
  const days = Math.floor(totalSeconds / 86400)
  const hours = Math.floor((totalSeconds % 86400) / 3600)
  const minutes = Math.floor((totalSeconds % 3600) / 60)
  const seconds = totalSeconds % 60
  return `${days}d ${hours}h ${minutes}m ${seconds}s`
}
