import { Router } from 'express'
import * as creatorController from './creator.controller.js'
import { requireAuth } from '../../shared/middleware/auth.js'
import { validate } from '../../shared/middleware/validate.js'
import { creatorSetupSchema } from './creator.schema.js'

const router = Router()

// Upgrade to Creator
router.post('/setup', requireAuth, validate(creatorSetupSchema), creatorController.setupCreator)

// Update Creator Profile
router.patch('/profile', requireAuth, creatorController.updateCreatorProfile)

export default router
