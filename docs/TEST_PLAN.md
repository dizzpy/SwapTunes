# SwapTunes - Test Plan

## Scope

Covers unit, widget, and integration tests for the Flutter frontend and unit + integration tests for the Node.js backend. E2E tests and Supabase internals are out of scope.

## Test Types

| Type                  | Tool                    | Purpose                               |
| --------------------- | ----------------------- | ------------------------------------- |
| Unit (Flutter)        | flutter_test + mocktail | ViewModel business logic in isolation |
| Widget (Flutter)      | flutter_test            | Screen rendering and UI state         |
| Integration (Flutter) | flutter_test + Isar     | Cache layer behavior                  |
| Unit (Backend)        | Jest                    | Service logic in isolation            |
| Integration (Backend) | Jest + Supertest        | API route contract testing            |

## Coverage Targets

- Flutter ViewModels: 80%+
- Backend Services: 70%+
- Backend Routes: critical paths only (auth, feed, AI, messaging)

## Exclusions

- Spotify OAuth (requires real tokens)
- Supabase Realtime (requires live connection)
- Push notifications (device-dependent)
- E2E (out of time scope for viva)
