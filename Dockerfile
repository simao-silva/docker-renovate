# renovate: datasource=npm depName=renovate versioning=npm
ARG RENOVATE_VERSION=34.21.3

# Base image
#============
FROM simaofsilva/renovatebot-docker-buildpack:latest@sha256:1971d6221623c394f67df17f6bb106b4558e9271f65eccdf0642f376edaf07bf AS base

LABEL name="renovate"
LABEL org.opencontainers.image.source="https://github.com/renovatebot/renovate" \
  org.opencontainers.image.url="https://renovatebot.com" \
  org.opencontainers.image.licenses="AGPL-3.0-only"

# renovate: datasource=github-tags depName=nodejs/node
RUN install-tool node v19.0.1

# renovate: datasource=npm depName=yarn versioning=npm
RUN install-tool yarn 1.22.19

WORKDIR /usr/src/app

# Build image
#============
FROM base as tsbuild

COPY . .

RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 make g++

RUN set -ex; \
  yarn config set network-timeout 600000; \
  yarn install; \
  yarn build; \
  chmod +x dist/*.js;

ARG RENOVATE_VERSION
RUN set -ex; \
  yarn version --new-version ${RENOVATE_VERSION}; \
  yarn add -E  renovate@${RENOVATE_VERSION} --production;  \
  npm i re2; \
  node -e "new require('re2')('.*').exec('test')";

# Final image
#============
FROM base as final

# renovate: datasource=github-releases depName=docker lookupName=moby/moby
RUN install-tool docker v20.10.21

ENV RENOVATE_BINARY_SOURCE=docker

COPY --from=tsbuild /usr/src/app/package.json package.json
COPY --from=tsbuild /usr/src/app/dist dist
COPY --from=tsbuild /usr/src/app/node_modules node_modules

# exec helper
COPY bin/ /usr/local/bin/
RUN ln -sf /usr/src/app/dist/renovate.js /usr/local/bin/renovate;
RUN ln -sf /usr/src/app/dist/config-validator.js /usr/local/bin/renovate-config-validator;
CMD ["renovate"]

RUN set -ex; \
  renovate --version; \
  renovate-config-validator; \
  node -e "new require('re2')('.*').exec('test')";

ARG RENOVATE_VERSION
LABEL org.opencontainers.image.version="${RENOVATE_VERSION}"

# Numeric user ID for the ubuntu user. Used to indicate a non-root user to OpenShift
USER 1000
