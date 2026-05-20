import { Router } from 'express'
import { getLiveness, getDetailedHealth, getAiHealth } from './health.controller.js'

const router = Router()

// GET /api/v1/health — liveness
router.get('/', getLiveness)

// GET /api/v1/health/detailed — readiness + dependency status
router.get('/detailed', getDetailedHealth)

// GET /api/v1/health/ai — per-key Gemini probe (honors x-gemini-key header)
router.get('/ai', getAiHealth)

export default router
