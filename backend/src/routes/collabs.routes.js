import { Router } from 'express'
import * as collabsController from '../controllers/collabs.controller.js'
import { requireAuth } from '../middleware/auth.js'
import { requireCreator } from '../middleware/requireCreator.js'
import { validate } from '../middleware/validate.js'
import { collabSchema } from '../utils/validators/collabs.schema.js'

const router = Router()

// Publicly viewable collabs (assuming authenticated users)
router.get('/', requireAuth, collabsController.getCollabs)
router.get('/:collabId', requireAuth, collabsController.getCollabById)

// Creator only actions
router.post('/', requireAuth, requireCreator, validate(collabSchema), collabsController.createCollab)
router.patch('/:collabId', requireAuth, requireCreator, collabsController.updateCollab)
router.delete('/:collabId', requireAuth, requireCreator, collabsController.deleteCollab)

export default router
