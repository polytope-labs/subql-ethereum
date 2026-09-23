# Same as packages/node/Dockerfile, but installs @subql/node-core from vendor/subql-node-core.tgz, which
# scripts/use-polytope-node-core.sh builds from polytope-labs/subql, instead of from npm.

# ---- Build Stage ----
FROM node:lts-alpine AS builder

WORKDIR /app
RUN apk add --no-cache python3 make g++ jq bash

COPY ./packages ./packages
COPY ./tsconfig.json ./tsconfig.json
COPY ./scripts/build.sh ./scripts/build.sh
COPY ./vendor/subql-node-core.tgz /vendor/subql-node-core.tgz

# An absolute path so the dependency still resolves when app.tgz is installed in the production stage
RUN jq '.dependencies["@subql/node-core"] = "file:/vendor/subql-node-core.tgz"' packages/node/package.json \
    > packages/node/package.tmp.json \
  && mv packages/node/package.tmp.json packages/node/package.json

RUN ./scripts/build.sh packages/node

# ---- Production Stage ----
FROM node:lts-alpine

ENV NODE_ENV=production
RUN apk add --no-cache tini python3 make g++

COPY --from=builder /app/packages/node/app.tgz ./app.tgz
COPY --from=builder /vendor/subql-node-core.tgz /vendor/subql-node-core.tgz

RUN npm install -g ./app.tgz \
  && rm -rf ./app.tgz /vendor \
  && npm cache clean --force \
  && rm -rf /root/.npm /root/.cache

# Remove packages required for building native node modules
RUN apk del python3 make g++

RUN mkdir -p .monitor && chown 1000:1000 .monitor

USER 1000
ENV TZ=utc

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/lib/node_modules/@subql/node-ethereum/bin/run"]
CMD ["-f", "/app"]
