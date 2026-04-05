import { Router } from 'express'
import multer from 'multer'
import { requireAuth } from '../../shared/middleware/auth.js'
import * as uploadsController from './uploads.controller.js'

const router = Router()

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024 // 10 MB max (Flutter compresses before sending)
  },
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true)
    } else {
      cb(Object.assign(new Error('Only image files are allowed'), { statusCode: 400 }))
    }
  }
})

router.post('/image', requireAuth, upload.single('file'), uploadsController.uploadImage)

export default router
