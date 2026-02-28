import { Router } from 'express'
import * as creatorController from '../controllers/creator.controller.js'
import { requireAuth } from '../middleware/auth.js'
import { validate } from '../middleware/validate.js'
import { creatorSetupSchema } from '../validators/creator.schema.js'

const router = Router()

// Upgrade to Creator
router.post('/setup', requireAuth, validate(creatorSetupSchema), creatorController.setupCreator)

export default router
