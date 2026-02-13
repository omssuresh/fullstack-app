# Stage 1: Build Angular application
FROM node:22-alpine as build

WORKDIR /app

# Copy package files
COPY package*.json ./

# Regenerate package-lock.json to fix sync issues
RUN npm install

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build application for production
RUN npm run build

# Stage 2: Serve with nginx
FROM nginx:alpine

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built application from build stage
COPY --from=build /app/dist/fullstack-frontend /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
