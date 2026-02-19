# SwapTunes Full Project Structure and Checklist

Hey Dizzpy, here is the full project blueprint you asked for. This covers both the Flutter frontend and the separate backend services with REST APIs, realtime, AI, infra, CI, testing, and what files and modules to add as you build. Save this as `SWAPTUNES_PROJECT_STRUCTURE.md` for reference.

## 1. Overview

SwapTunes is split into multiple services so everything scales cleanly:

* Frontend: Flutter mobile app
* Backend API: Node JS Express service(s)
* Realtime: Socket.io server or realtime microservice
* Database + Auth: Supabase (Postgres + RLS + Auth)
* AI Services: Python or Node microservice for ML tasks
* Integrations: Spotify API, Google Sign In, Push notifications

## 2. High level repo strategy

I recommend multiple repos, one per major service, plus infra repo. Example layout:

* swap-tunes-mobile  (Flutter app)
* swap-tunes-api     (Node JS REST API)
* swap-tunes-realtime (Socket server)
* swap-tunes-ai      (ML models and AI endpoints)
* infra              (IaC, deployment manifests)
* docs               (specs, API contracts, guides)

You can also use a mono repo if you prefer, but multiple repos map cleaner to CI pipelines and deployments.

## 3. Frontend repo structure (Flutter)

Create `lib` with feature based layout and shared modules. Use this layout exactly:

```
lib/
  features/
    auth/
      data/
      domain/
      presentation/
      tests/
    playlists/
      data/
      domain/
      presentation/
      tests/
    social/
      data/
      domain/
      presentation/
      tests/
    music_dna/
      data/
      domain/
      presentation/
      tests/
    ai_playlists/
      data/
      domain/
      presentation/
      tests/
    live_moments/
      data/
      domain/
      presentation/
      tests/
    smart_matching/
      data/
      domain/
      presentation/
      tests/
  shared/
    widgets/
    theme/
      app_text_styles.dart
      app_colors.dart
      app_theme.dart
    constants/
      spacing.dart
      sizes.dart
      strings.dart
    services/
      api_client.dart
      auth_service.dart
      spotify_service.dart
      realtime_client.dart
    models/
    utils/
    di/            // dependency injection / service locator
  core/
    network/
    errors/
    logger.dart
  main.dart
  env.dart
integration_test/
test/
  unit/
  widget/
  integration/
assets/
  fonts/
  images/
pubspec.yaml
```

### notes

* Put actual text sizes file under `shared/theme/app_text_styles.dart`
* `services/api_client.dart` handles REST calls to your Node API and token refresh
* `realtime_client.dart` abstracts Socket.io or WebSocket connection
* tests folders mirror features so tests stay close to code

## 4. Backend repo structure (Node JS Express)

This service is your primary REST API connecting mobile app and other services. Use TypeScript.

```
src/
  controllers/
    auth.controller.ts
    users.controller.ts
    playlists.controller.ts
    social.controller.ts
    realtime.controller.ts
    ai.controller.ts
  routes/
    auth.routes.ts
    users.routes.ts
    playlists.routes.ts
    social.routes.ts
    ai.routes.ts
  services/
    auth.service.ts
    spotify.service.ts
    user.service.ts
    playlist.service.ts
    ai_client.service.ts
  models/
    user.model.ts
    playlist.model.ts
    follow.model.ts
  db/
    index.ts         // supabase or pg client init
    migrations/
  middleware/
    auth.middleware.ts
    rls.middleware.ts
    error.middleware.ts
  utils/
    validators.ts
    logger.ts
  config/
    index.ts
  app.ts
  server.ts
tests/
  unit/
  integration/
package.json
tsconfig.json
```

### Backend responsibilities

* Serve REST endpoints consumed by mobile app
* Validate requests and enforce RLS where appropriate
* Handle OAuth flow with Spotify and Google
* Issue short lived tokens for mobile or rely on Supabase Auth directly
* Orchestrate calls to AI microservice for playlist generation
* Emit events to realtime server for live sessions

## 5. Realtime service structure

If you choose a separate realtime service for scale:

```
src/
  index.ts          // socket server bootstrap
  handlers/
    room.handler.ts
    sync.handler.ts
    presence.handler.ts
  services/
    room.service.ts
    sync.service.ts
  auth/
    socketAuth.ts
  utils/
  config/
package.json
```

### responsibilities

* Manage live rooms and presence
* Broadcast playback sync events
* Keep light persistence or call backend API for heavy ops
* Validate user tokens on socket connect

## 6. AI microservice structure

This can be Python Flask/FastAPI or Node. Use Python if using ML libraries.

```
app/
  main.py
  routes/
    playlist_gen.py
    dna_analysis.py
  models/
    model_loader.py
    predictors.py
  utils/
    spotify_feature_extractor.py
  requirements.txt
Dockerfile
tests/
```

### responsibilities

* Run ML models that calculate music DNA, mood, recommendations
* Expose small REST endpoints token protected
* Accept batched requests from backend for async processing

## 7. Supabase schema and key tables

Design Postgres tables for core functionality. Basic set:

* users
  * id
  * name
  * email
  * avatar_url
  * spotify_id
  * created_at
* playlists
  * id
  * owner_id
  * title
  * description
  * public
  * metadata jsonb
  * created_at
* playlist_items
  * id
  * playlist_id
  * track_id
  * position
* follows
  * follower_id
  * followee_id
  * created_at
* likes
  * user_id
  * playlist_id
  * created_at
* live_rooms
  * id
  * host_id
  * metadata jsonb
  * created_at
* events
  * id
  * room_id
  * event_type
  * payload jsonb
  * created_at

### Supabase rules and RLS

* Enforce RLS so only owners can edit playlists
* Public read on public playlists only
* Separate role for server service to perform server side operations

## 8. REST API contract examples

These are minimal examples to get you started. Use consistent JSON shapes and HTTP status codes.

### Auth

POST /api/v1/auth/login
Request
```
{
  "provider": "email" or "google" or "spotify",
  "token": "<oauth_token_or_email_creds>"
}
```
Response
```
{
  "accessToken": "<jwt>",
  "refreshToken": "<refresh>",
  "user": { "id": "...", "name": "...", "email": "..." }
}
```

### Playlists

GET /api/v1/playlists?limit=20&page=1
Response
```
{
  "items": [ { "id": "...", "title": "...", "owner": {...} } ],
  "meta": { "page": 1, "limit": 20, "total": 123 }
}
```

POST /api/v1/playlists
Request
```
{
  "title": "Chill coding",
  "description": "songs for focus",
  "tracks": [ { "trackId": "spotify:track:..." }, ... ],
  "public": true
}
```
Response 201
```
{ "id": "...", "ownerId": "...", "createdAt": "..." }
```

### Social

POST /api/v1/users/:id/follow
Response 200
```
{ "followed": true }
```

### AI

POST /api/v1/ai/playlist
Request
```
{
  "userId": "...",
  "context": "study session at night",
  "seedTracks": ["spotify:track:..."]
}
```
Response
```
{ "playlistId": "...", "tracks": [ { "id": "...", "reason": "energy match" } ] }
```

## 9. Auth strategy

* Use Supabase Auth for email, passwordless, social providers
* For server to server calls, use service_role key securely
* On mobile, use Supabase SDK for session management or use your own auth that delegates to Supabase
* Refresh tokens via Supabase or your own refresh endpoint

## 10. Devops and infra

Consider using this stack

* Containerization: Docker for services
* Orchestration: Kubernetes or simple ECS for prototypes
* CI: GitHub Actions
* CD: GitHub Actions workflows that build images and deploy to cluster
* Secrets: Vault or cloud secret manager
* Monitoring: Sentry for errors, Prometheus for metrics
* Logging: Structured logs to cloud logging (Stackdriver/Datadog)

### Example GitHub Actions jobs

* lint and typecheck
* run unit tests
* build docker image
* push to registry
* run integration tests against a deploy preview

## 11. Local development tips

* Use docker compose with supabase or Postgres locally
* Use env files per service
* Mock Spotify responses during development using saved fixtures
* Start realtime server separately and point Flutter to local socket endpoint
* Use ngrok if you need to test webhooks or mobile callback flows

## 12. Testing strategy summary

* Frontend unit, widget, integration tests
* Backend unit and integration tests
* Realtime tests that simulate multiple clients
* Contract tests between backend and AI service
* E2E smoke tests after deployment

## 13. CI checklist

* run linters
* run tests
* ensure infra templates validate
* build and push images on main
* deploy to staging for smoke tests

## 14. Security checklist

* Do not commit secrets
* Rotate service_role keys periodically
* Use RLS for Supabase and validate all writes
* Rate limit endpoints that call third party APIs
* Validate and sanitize any external inputs

## 15. Docs to maintain in docs repo

* API contract (OpenAPI spec)
* Database schema and migration notes
* Auth flows
* Realtime events spec
* Deployment runbook
* Onboarding guide for new devs

## 16. Starter todo list

* scaffold repos and CI
* create supabase schema and seed data
* scaffold Flutter features with empty screens
* implement auth flow and Spotify OAuth
* implement playlist CRUD with backend and mobile
* add tests for core features
* scaffold realtime room and simple sync proof of concept
* integrate AI microservice minimal endpoint

## 17. References

* Spotify Developer docs
* Supabase docs
* Socket.io docs
* FastAPI or Flask docs for AI microservice

---

If you want I can generate this as a downloadable markdown file for you right now. I can also create an OpenAPI spec stub or empty repo scaffolding. Tell me which one to produce next and I will make it.
