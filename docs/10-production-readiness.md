# SwapTunes — Production Readiness Plan

This document outlines the essential improvements, security enhancements, and architectural upgrades required before deploying the SwapTunes backend to a production environment.

---

## 1. Security & Shielding
Before exposing the API to the public internet, we must ensure it is resilient against common attacks and abuse.

### a. Rate Limiting (`express-rate-limit`)
- **Global Limit:** Limit IP addresses to a reasonable number of requests (e.g., 100 requests per 15 minutes) to deter DDoS attacks and simple scraping.
- **Strict Limits:** Apply stricter rules to sensitive routes:
  - `POST /auth/profile/setup`: max 5 requests per hour.
  - `POST /posts/:id/comments`: max 20 comments per minute.
  - `POST /posts`: max 10 posts per minute to prevent spam.

### b. Request Sanitization & Validation
- We are currently using `zod` for validation, which is excellent. We need to ensure that **all** incoming `req.body`, `req.query`, and `req.params` are parsed through strict Zod schemas.
- Implement deep sanitization to prevent NoSQL/SQL injection (Supabase handles much of this, but backend validation is the first line of defense).

### c. Safe Headers
- `helmet` is already installed, which is great. We should verify its configuration for Production (e.g., HSTS strict transport security, cross-site scripting filters).

---

## 2. Architecture & Reliability

### a. Environment Variable Validation
- **Problem:** If a critical variable (like `SUPABASE_SERVICE_ROLE_KEY`) is missing, the app boots up but fails abruptly when trying to use it.
- **Solution:** Create a strict `zod` schema in `src/config/env.js` that parses and validates `process.env` before `app.listen()` is called. If requirements aren't met, the application should `throw` and refuse to boot, with a clear error message.

### b. Graceful Shutdown
- When the server receives a `SIGINT` (Ctrl+C) or `SIGTERM` (Docker/K8s stop command), it instantly kills all active requests.
- **Solution:** Catch these signals, stop accepting new HTTP requests, wait for ongoing database transactions to finish, and finally call `process.exit(0)`.

### c. Global Unhandled Error Catchers
- Uncaught exceptions or unhandled promise rejections can crash the Node.js process.
- **Solution:** Attach event listeners to `process.on('uncaughtException')` and `process.on('unhandledRejection')` to log the critical failure and then gracefully shut down.

---

## 3. Error Handling Reform

### a. Custom Error Classes
Currently, endpoints might return generic errors or unstructured objects. We need a unified error system:
```javascript
class AppError extends Error {
  constructor(message, statusCode, code) { ... }
}
class NotFoundError extends AppError { ... }
class UnauthorizedError extends AppError { ... }
```
- Controllers will `throw new NotFoundError('User not found')`, and the central `errorHandler.js` will catch it and format it consistently.

### b. Unified API Responses
- Ensure every single response matches a consistent structure:
  - **Success:** `{ "status": "success", "data": { ... } }`
  - **Error:** `{ "status": "error", "error": { "code": "...", "message": "..." } }`

---

## 4. Observability & Logging

### a. Structured Logging (`pino` / `winston`)
- `console.log()` is synchronous and lacks structure.
- **Solution:** Implement a fast JSON logger like `pino`. This ensures logs can be easily parsed by Datadog, AWS CloudWatch, or Google Cloud Logging. Logs should include trace IDs, timestamps, and severity levels (INFO, WARN, ERROR).

### b. Request Logging (`morgan`)
- Log every incoming request and its response time, HTTP status, and payload size.
- **Solution:** Format logs differently based on the environment. (`dev` = colorful concise text, `production` = dense JSON).

---

## 5. Deployment Setup

### a. Dockerization
- Create a highly unprivileged `Dockerfile` to package the Node.js app.
- Multi-stage build to keep the image size small (e.g., building dependencies, then copying only the runtime files).

### b. CI/CD Pipeline
- Implement a GitHub Actions workflow that:
  1. Runs ESLint.
  2. Runs Unit Tests (Next step).
  3. Builds the Docker Image.
  4. Deploys to the chosen cloud provider (e.g., AWS, Render, DigitalOcean).

---

## 6. Testing Strategy

### a. Unit Tests (Jest)
- Test utility functions, Zod validators, and core business logic without hitting the actual database.

### b. Integration Tests (Supertest)
- Spin up an isolated local server and simulate HTTP requests to the endpoints to verify routing, middleware, and correct HTTP status codes in responses.

---

## 7. Performance Optimizations

### a. Pagination Optimization
- Ensure every endpoint returning a list (feed, comments, followers) strictly uses cursor-based pagination (which is currently defined in specs) rather than offset-pagination for massive performance gains at scale.

### b. Payload Compression (`compression`)
- Add the `compression` middleware to GZIP JSON responses, drastically reducing payload sizes over the network.
