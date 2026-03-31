import { Router } from 'express'
import { env } from '../../config/env.js'
import * as devController from './dev.controller.js'

const router = Router()

// Block in production
router.use((req, res, next) => {
  if (env.NODE_ENV === 'production') {
    return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Not found' } })
  }
  next()
})

// POST /dev/reset-role  { username, role, clear_creator_profile? }
router.post('/reset-role', devController.resetRole)

export default router
