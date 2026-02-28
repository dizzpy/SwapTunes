import { Router } from 'express'
import authRoutes from './auth.routes.js'
import usersRoutes from './users.routes.js'
import creatorRoutes from './creator.routes.js'
import postsRoutes from './posts.routes.js'
import discoverRoutes from './discover.routes.js'
import playlistsRoutes from './playlists.routes.js'
import collabsRoutes from './collabs.routes.js'
import conversationsRoutes from './conversations.routes.js'
import notificationsRoutes from './notifications.routes.js'

const router = Router()

router.get('/health', (req, res) => res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() }))

router.use('/auth', authRoutes)
router.use('/users', usersRoutes)
router.use('/creator', creatorRoutes)
router.use('/posts', postsRoutes)
router.use('/discover', discoverRoutes)
router.use('/playlists', playlistsRoutes)
router.use('/collabs', collabsRoutes)
router.use('/conversations', conversationsRoutes)
router.use('/notifications', notificationsRoutes)

export { router }
