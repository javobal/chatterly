# build image
FROM node:20-alpine as build
ENV NODE_ENV=development
WORKDIR /usr/src/app

COPY package*.json ./
#COPY yarn.lock ./
RUN npm install

COPY . .
RUN npm run build:docker

# deploy image
FROM node:20-alpine as deploy
ARG PORT=3000
ARG NODE_ENV=production

ENV PORT=$PORT
ENV NODE_ENV=$NODE_ENV

WORKDIR /usr/src/app
COPY --from=build /usr/src/app .

EXPOSE $PORT
CMD node dist/index.js