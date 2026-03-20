import { Router } from 'express'
import healthRoutes from './features/health/health.routes.js'
import authRoutes from './features/auth/auth.routes.js'
import usersRoutes from './features/users/users.routes.js'
import creatorRoutes from './features/creator/creator.routes.js'
import postsRoutes from './features/posts/posts.routes.js'
import discoverRoutes from './features/discover/discover.routes.js'
import playlistsRoutes from './features/playlists/playlists.routes.js'
import collabsRoutes from './features/collabs/collabs.routes.js'
import conversationsRoutes from './features/messaging/conversations.routes.js'
import notificationsRoutes from './features/notifications/notifications.routes.js'
import uploadsRoutes from './features/uploads/uploads.routes.js'

const router = Router()

router.use('/health', healthRoutes)

router.use('/auth', authRoutes)
router.use('/users', usersRoutes)
router.use('/creator', creatorRoutes)
router.use('/posts', postsRoutes)
router.use('/discover', discoverRoutes)
router.use('/playlists', playlistsRoutes)
router.use('/collabs', collabsRoutes)
router.use('/conversations', conversationsRoutes)
router.use('/notifications', notificationsRoutes)
router.use('/uploads', uploadsRoutes)

export { router }
