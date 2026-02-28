# SwapTunes — Backend Structure
> Node.js + Express.js  
> Language: JavaScript (or TypeScript recommended)  
> Pattern: Layered Architecture (Routes → Controllers → Services → DB)

---

## Folder Structure

```
swaptunes-backend/
│
├── src/
│   │
│   ├── config/
│   │   ├── supabase.js          # Supabase client init (service role key)
│   │   ├── spotify.js           # Spotify API client setup
│   │   └── env.js               # Environment variable validation
│   │
│   ├── middleware/
│   │   ├── auth.js              # Verify Supabase JWT, attach user to req
│   │   ├── requireCreator.js    # Guard: user_type must be 'creator'
│   │   ├── requireOwner.js      # Guard: user must own the resource
│   │   ├── requireSpotify.js    # Guard: user must have Spotify connected
│   │   ├── validate.js          # Request body validation (joi/zod)
│   │   └── errorHandler.js      # Global error handler middleware
│   │
│   ├── routes/
│   │   ├── index.js             # Mounts all route groups under /api/v1
│   │   ├── auth.routes.js       # /auth/*
│   │   ├── users.routes.js      # /users/*
│   │   ├── creator.routes.js    # /creator/*
│   │   ├── posts.routes.js      # /posts/*
│   │   ├── discover.routes.js   # /discover/*
│   │   ├── playlists.routes.js  # /playlists/*
│   │   ├── collabs.routes.js    # /collabs/*
│   │   ├── conversations.routes.js  # /conversations/*
│   │   └── notifications.routes.js  # /notifications/*
│   │
│   ├── controllers/
│   │   ├── auth.controller.js
│   │   ├── users.controller.js
│   │   ├── creator.controller.js
│   │   ├── posts.controller.js
│   │   ├── discover.controller.js
│   │   ├── playlists.controller.js
│   │   ├── collabs.controller.js
│   │   ├── conversations.controller.js
│   │   └── notifications.controller.js
│   │
│   ├── services/
│   │   ├── auth.service.js          # Profile setup, Spotify token storage
│   │   ├── users.service.js         # Profile reads, follow/unfollow logic
│   │   ├── creator.service.js       # Creator mode switch, profile updates
│   │   ├── posts.service.js         # Feed algorithm, CRUD, like/comment
│   │   ├── discover.service.js      # Playlist discovery, search logic
│   │   ├── playlists.service.js     # Spotify API calls, import to DB
│   │   ├── collabs.service.js       # Collab CRUD, filtering
│   │   ├── conversations.service.js # DM thread management, message insert
│   │   ├── notifications.service.js # Notification creation helper
│   │   └── spotify.service.js       # Spotify API wrapper (token refresh etc)
│   │
│   ├── utils/
│   │   ├── response.js          # Standard success/error response helpers
│   │   ├── pagination.js        # Cursor-based pagination helpers
│   │   └── validators/
│   │       ├── auth.schema.js
│   │       ├── posts.schema.js
│   │       └── collabs.schema.js
│   │
│   └── app.js                   # Express app setup (middleware, routes)
│
├── server.js                    # Entry point — starts HTTP server
├── .env                         # Environment variables (never commit)
├── .env.example                 # Template for env vars
├── package.json
└── README.md
```

---

## Key Files Explained

### `src/app.js`
```js
import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import { router } from './routes/index.js'
import { errorHandler } from './middleware/errorHandler.js'

const app = express()

app.use(helmet())
app.use(cors())
app.use(express.json())

app.use('/api/v1', router)
app.use(errorHandler)

export default app
```

---

### `src/routes/index.js`
```js
import { Router } from 'express'
import authRoutes         from './auth.routes.js'
import usersRoutes        from './users.routes.js'
import creatorRoutes      from './creator.routes.js'
import postsRoutes        from './posts.routes.js'
import discoverRoutes     from './discover.routes.js'
import playlistsRoutes    from './playlists.routes.js'
import collabsRoutes      from './collabs.routes.js'
import conversationsRoutes from './conversations.routes.js'
import notificationsRoutes from './notifications.routes.js'

const router = Router()

router.use('/auth',          authRoutes)
router.use('/users',         usersRoutes)
router.use('/creator',       creatorRoutes)
router.use('/posts',         postsRoutes)
router.use('/discover',      discoverRoutes)
router.use('/playlists',     playlistsRoutes)
router.use('/collabs',       collabsRoutes)
router.use('/conversations', conversationsRoutes)
router.use('/notifications', notificationsRoutes)

export { router }
```

---

### `src/middleware/auth.js`
```js
import { supabase } from '../config/supabase.js'

export const requireAuth = async (req, res, next) => {
  const token = req.headers.authorization?.split('Bearer ')[1]
  if (!token) return res.status(401).json({ error: { code: 'UNAUTHORIZED' } })

  const { data: { user }, error } = await supabase.auth.getUser(token)
  if (error || !user) return res.status(401).json({ error: { code: 'UNAUTHORIZED' } })

  // Fetch full user row from public.users
  const { data: dbUser } = await supabase
    .from('users')
    .select('*')
    .eq('id', user.id)
    .single()

  req.user = dbUser
  next()
}
```

---

### `src/middleware/requireCreator.js`
```js
export const requireCreator = (req, res, next) => {
  if (req.user?.user_type !== 'creator') {
    return res.status(403).json({
      error: { code: 'FORBIDDEN', message: 'Creator account required.' }
    })
  }
  next()
}
```

---

### `src/utils/response.js`
```js
export const success = (res, data, status = 200) => {
  res.status(status).json(data)
}

export const fail = (res, code, message, status = 400) => {
  res.status(status).json({ error: { code, message } })
}
```

---

### `src/services/notifications.service.js`
```js
import { supabase } from '../config/supabase.js'

export const createNotification = async ({ userId, actorId, type, referenceId }) => {
  await supabase.from('notifications').insert({
    user_id: userId,
    actor_id: actorId,
    type,
    reference_id: referenceId
  })
}
```
> This service is called by `posts.service`, `users.service`, `collabs.service`, and `conversations.service` after their respective actions.

---

## Middleware Chain

Every protected route passes through this chain:

```
Request
  │
  ▼
requireAuth          → verifies JWT, attaches req.user
  │
  ▼
requireCreator?      → only on /collabs/* routes
  │
  ▼
requireSpotify?      → only on /playlists/spotify/* routes
  │
  ▼
validate(schema)?    → validates req.body with zod/joi
  │
  ▼
Controller           → calls service, returns response
  │
  ▼
errorHandler         → catches any thrown errors globally
```

---

## NPM Dependencies

### Core
| Package | Purpose |
|---------|---------|
| `express` | HTTP framework |
| `@supabase/supabase-js` | Supabase client (DB + Auth) |
| `dotenv` | Environment variable loading |
| `cors` | Cross-origin requests |
| `helmet` | Security headers |

### Validation
| Package | Purpose |
|---------|---------|
| `zod` or `joi` | Request body schema validation |

### Spotify
| Package | Purpose |
|---------|---------|
| `axios` | HTTP client for Spotify API calls |

### Dev
| Package | Purpose |
|---------|---------|
| `nodemon` | Auto-restart on file change |
| `eslint` | Code linting |

---

## Scripts (`package.json`)

```json
{
  "scripts": {
    "start":   "node server.js",
    "dev":     "nodemon server.js",
    "lint":    "eslint src/"
  }
}
```

---

## Environment Variables

```env
# Supabase
SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR...

# Spotify
SPOTIFY_CLIENT_ID=your_spotify_client_id
SPOTIFY_CLIENT_SECRET=your_spotify_client_secret
SPOTIFY_REDIRECT_URI=your_redirect_uri

# App
PORT=3000
NODE_ENV=development
```

> ⚠️ Never commit `.env` to git. Use `.env.example` as a template.
