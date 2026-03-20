import { UTApi, UTFile } from 'uploadthing/server'
import { success } from '../../shared/utils/response.js'

const utapi = new UTApi()

// Upload image controller — receives file via multer memory storage,
// uploads to UploadThing via UTApi, and returns the CDN URL.
export const uploadImage = async (req, res, next) => {
  try {
    if (!req.file) {
      return next({ statusCode: 400, code: 'NO_FILE', message: 'No file provided' })
    }

    const file = new UTFile([req.file.buffer], req.file.originalname, {
      type: req.file.mimetype
    })

    const response = await utapi.uploadFiles(file)

    if (response.error) {
      return next({ statusCode: 400, code: 'UPLOAD_FAILED', message: response.error.message })
    }

    success(res, { url: response.data.url })
  } catch (err) {
    next(err)
  }
}
