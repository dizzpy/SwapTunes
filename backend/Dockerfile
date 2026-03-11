# ---- base: shared node setup ----
FROM node:20-alpine AS base
WORKDIR /app
COPY package*.json ./

# ---- dev: all deps + hot-reload ----
FROM base AS dev
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]

# ---- deps: production-only node_modules ----
FROM base AS deps
RUN npm ci --omit=dev

# ---- prod: lean final image ----
FROM node:20-alpine AS prod
WORKDIR /app

# Non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:3000/api/v1/health || exit 1

CMD ["node", "server.js"]
