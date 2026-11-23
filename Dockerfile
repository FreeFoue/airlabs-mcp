FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY tsconfig.json index.ts ./
RUN npm run build

FROM node:22-alpine
ENV NODE_ENV=production MCP_TRANSPORT=http PORT=3000
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force
COPY --from=build /app/build ./build
USER node
EXPOSE 3000
CMD ["node", "build/index.js"]
