# renovate: datasource=npm depName=renovate versioning=npm
ARG RENOVATE_VERSION=36.41.0

# Base image
#============
FROM simaofsilva/containerbase-buildpack:8.0.5@sha256:e21b79e72c00c73089d8358ac08ad9a6f75d5e4dbb23f0c57c802c86d81d69e7 AS base

# renovate: datasource=github-tags depName=nodejs/node
RUN install-tool node v20.5.1

# renovate: datasource=npm depName=yarn versioning=npm
RUN install-tool yarn 1.22.19

WORKDIR /usr/src/app

# renovate: datasource=github-releases depName=docker lookupName=moby/moby
RUN install-tool docker v24.0.5

ENV RENOVATE_BINARY_SOURCE=docker

COPY bin/ /usr/local/bin/
CMD ["renovate"]

ARG RENOVATE_VERSION

RUN apt update && \
    apt install -y --no-install-recommends python3 make g++ && \
    install-tool renovate && \
    apt autoremove -y python3 make g++ && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* /usr/share/doc /usr/share/man

# Compabillity, so `config.js` can access renovate and deps
RUN ln -sf /opt/buildpack/tools/renovate/${RENOVATE_VERSION}/node_modules ./node_modules;

RUN set -ex; \
  renovate --version; \
  renovate-config-validator; \
  node -e "new require('re2')('.*').exec('test')"; \
  true

# Numeric user ID for the ubuntu user. Used to indicate a non-root user to OpenShift
USER 1000
