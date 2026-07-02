FROM node:20-alpine

# Install build dependencies for native modules if needed
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Copy package files first to leverage Docker cache
COPY package*.json ./

# Install all dependencies (including devDependencies for the build step)
RUN npm install

# Copy the rest of the application source
COPY . .

# Build the TypeScript code
RUN npm run build

# Remove devDependencies to keep the image small
RUN npm prune --production

# Expose the backend port
EXPOSE 3001

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3001

# Start the server
CMD ["node", "dist/index.js"]
