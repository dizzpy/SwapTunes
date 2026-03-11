# SwapTunes — Backend Structure
> Node.js + Express.js  
> Language: JavaScript (or TypeScript recommended)  
> Pattern: Layered Architecture + Event-Driven + Repository Pattern

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
│   │   ├── validate.js          # Runs Zod schemas before controllers
│   │   ├── rateLimiter.js       # Rate limiting to prevent API abuse
│   │   └── errorHandler.js      # Global error handler middleware
│   │
│   ├── routes/                  # Route definitions mounting controllers
│   ├── controllers/             # Handles req/res object mapping
│   │
│   ├── services/                # Business logic only
│   │   ├── posts.service.js
│   │   ├── users.service.js
│   │   ├── collabs.service.js
│   │   └── ...
│   │
│   ├── repositories/            # DB queries only (Clean Data Access Layer)
│   │   ├── posts.repository.js
│   │   ├── users.repository.js
│   │   ├── collabs.repository.js
│   │   └── ...
│   │
│   ├── events/                  # Event-driven side effects (EventEmitter)
│   │   ├── emitter.js           # Single EventEmitter instance
│   │   └── listeners/
│   │       ├── notification.listener.js
│   │       └── feed.listener.js
│   │
│   ├── jobs/                    # Background scheduled tasks
│   │   └── spotify-token-refresh.job.js
│   │
│   ├── validators/              # Dedicated Zod input validation schemas
│   │   ├── auth.schema.js
│   │   ├── posts.schema.js
│   │   └── users.schema.js
│   │
│   ├── types/                   # Shared data shapes / JSdoc types
│   │
│   ├── utils/
│   │   ├── response.js          # Standard success/error response helpers
│   │   ├── pagination.js        # Cursor-based pagination helpers
│   │   └── logger.js            # Structured production logging (Pino/Winston)
│   │
│   └── app.js                   # Express app setup (middleware, routes)
│
├── server.js                    # Entry point — starts HTTP server
├── .env                         # Environment variables (never commit)
├── .env.example                 # Template for env vars
└── package.json
```

---

## The 4 Key Production Additions

### 1. Event-Driven Notifications (EventEmitter)
Instead of tightly coupling `likes` and `notifications` in the same service, we decouple them using Node.js `EventEmitter`. The service emits an event, and the listeners execute side-effects in the background.

```js
// src/services/posts.service.js
import emitter from '../events/emitter.js'

export const likePost = async (postId, userId) => {
  await postsRepository.addLike(postId, userId);
  emitter.emit('post.liked', { postId, userId }); // Fire and forget
}
```

```js
// src/events/listeners/notification.listener.js
import emitter from '../emitter.js'
import { notificationsRepository } from '../../repositories/notifications.repository.js'

emitter.on('post.liked', async ({ postId, userId }) => {
  await notificationsRepository.createNotification({ type: 'like', referenceId: postId, userId });
});
```

### 2. Input Validation Layer (Zod)
All API requests are strictly validated using dedicated schema files before hitting business logic.

```js
// src/validators/posts.schema.js
import { z } from 'zod';

export const createPostSchema = z.object({
  content: z.string().min(1).max(2000),
  image_url: z.string().url().optional()
});
```

### 3. Background Jobs (node-cron)
Spotify access tokens expire every hour. Instead of lazy-refreshing, we proactively refresh tokens via a background cron job.

```js
// src/jobs/spotify-token-refresh.job.js
import cron from 'node-cron';

cron.schedule('*/45 * * * *', async () => {
  console.log('Refreshing expiring Spotify tokens...');
  // Logic to find all users with spotify_connected = true and refresh tokens
});
```

### 4. Rate Limiting + Security Hardening
Using `express-rate-limit`, `helmet`, and structured logging (`winston`/`pino`), we protect endpoints and have full visibility into production requests.

---

## Middleware Chain

Every protected route passes through this chain:

```
Request
  │
  ▼
rateLimiter          → Global or route-specific API abuse prevention
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
validate(schema)?    → Uses /validators/ Zod schemas
  │
  ▼
Controller           → Maps request, calls service, returns response via utils/response.js
  │
  ▼
errorHandler         → catches any thrown errors globally
```

---

## NPM Dependencies Overview

### Core & Production
| Package | Purpose |
|---------|---------|
| `express` | HTTP framework |
| `@supabase/supabase-js` | Supabase DB/Auth client |
| `pino` or `winston` | Structured logging |
| `express-rate-limit` | API request limiting |
| `helmet` | Security headers |
| `node-cron` | Background job scheduling |

### Validation
| Package | Purpose |
|---------|---------|
| `zod` | Request body schema validation |

### Spotify
| Package | Purpose |
|---------|---------|
| `axios` | HTTP client for Spotify API calls |
