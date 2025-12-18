# syntax=docker/dockerfile:1.4

ARG NODE_VERSION=20

#################################
# Dependencies Stage
#################################
FROM node:${NODE_VERSION}-alpine AS deps

RUN corepack enable pnpm

WORKDIR /workspace

# Copy workspace configuration from monorepo context
COPY --from=monorepo pnpm-workspace.yaml pnpm-lock.yaml package.json tsconfig.base.json tsconfig.json ./

# Copy package.json from local context (apps/sdf)
COPY package.json ./apps/sdf/

# Install dependencies using pnpm workspace
RUN pnpm install --frozen-lockfile --filter sdf

#################################
# Builder Stage
#################################
FROM node:${NODE_VERSION}-alpine AS builder

RUN corepack enable pnpm

WORKDIR /workspace

# Copy installed dependencies
COPY --from=deps /workspace/node_modules ./node_modules
COPY --from=deps /workspace/apps/sdf/node_modules ./apps/sdf/node_modules
COPY --from=deps /workspace/pnpm-workspace.yaml /workspace/package.json /workspace/pnpm-lock.yaml /workspace/tsconfig.base.json /workspace/tsconfig.json ./

# Copy Vite app from local context (apps/sdf)
COPY . ./apps/sdf

ENV NODE_ENV=production

# Build the Vite app
WORKDIR /workspace/apps/sdf
RUN pnpm exec vite build

#################################
# Runner Stage
#################################
FROM nginx:alpine AS runner

WORKDIR /usr/share/nginx/html

# Copy custom nginx config
COPY --from=builder /workspace/apps/sdf/nginx.conf /etc/nginx/conf.d/default.conf

# Copy built static files
COPY --from=builder /workspace/apps/sdf/dist ./

# Copy env-config.js for runtime environment variables
COPY --from=builder /workspace/apps/sdf/public/env-config.js ./

# Copy entrypoint script
COPY --from=builder /workspace/apps/sdf/entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
