import { Router } from 'express'
import * as collabsController from './collabs.controller.js'
import { requireAuth } from '../../shared/middleware/auth.js'
import { requireCreator } from '../../shared/middleware/requireCreator.js'
import { validate } from '../../shared/middleware/validate.js'
import { collabSchema } from './collabs.schema.js'

const router = Router()

// Publicly viewable collabs (assuming authenticated users)
router.get('/', requireAuth, collabsController.getCollabs)

// Creator only actions
router.get('/me', requireAuth, requireCreator, collabsController.getMyCollabs)

router.get('/:collabId', requireAuth, collabsController.getCollabById)

// Creator only actions
router.post('/', requireAuth, requireCreator, validate(collabSchema), collabsController.createCollab)
router.patch('/:collabId', requireAuth, requireCreator, collabsController.updateCollab)
router.delete('/:collabId', requireAuth, requireCreator, collabsController.deleteCollab)

// AI Collab Match — creator only
router.post('/:collabId/match', requireAuth, requireCreator, collabsController.getCollabMatches)

export default router
