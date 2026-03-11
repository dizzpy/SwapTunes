import { Router } from 'express'
import { getLiveness, getDetailedHealth } from './health.controller.js'

const router = Router()

// GET /api/v1/health — liveness
router.get('/', getLiveness)

// GET /api/v1/health/detailed — readiness + dependency status
router.get('/detailed', getDetailedHealth)

export default router
