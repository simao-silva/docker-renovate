# renovate: datasource=npm depName=renovate versioning=npm
ARG RENOVATE_VERSION=34.117.2

# Base image
#============
FROM simaofsilva/containerbase-buildpack:6.0.3@sha256:b5f31f01c0a0f887f4fd9ba2501b6c29307cdc50c83fe2c8fbf99f19f52611b6 AS base

# renovate: datasource=github-tags depName=nodejs/node
RUN install-tool node v19.5.0

# renovate: datasource=npm depName=yarn versioning=npm
RUN install-tool yarn 1.22.19

WORKDIR /usr/src/app

# renovate: datasource=github-releases depName=docker lookupName=moby/moby
RUN install-tool docker v20.10.23

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
