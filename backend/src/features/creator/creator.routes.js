import { Router } from 'express'
import * as creatorController from './creator.controller.js'
import { requireAuth } from '../../shared/middleware/auth.js'
import { requireCreator } from '../../shared/middleware/requireCreator.js'
import { validate } from '../../shared/middleware/validate.js'
import { creatorSetupSchema } from './creator.schema.js'

const router = Router()

// Upgrade to Creator (first-time or re-activation)
router.post('/setup', requireAuth, validate(creatorSetupSchema), creatorController.setupCreator)

// Update Creator Profile
router.patch('/profile', requireAuth, requireCreator, creatorController.updateCreatorProfile)

// Switch back to Listener
router.post('/deactivate', requireAuth, requireCreator, creatorController.deactivateCreator)

export default router
