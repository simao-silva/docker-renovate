# renovate: datasource=npm depName=renovate versioning=npm
ARG RENOVATE_VERSION=35.118.0

# Base image
#============
FROM simaofsilva/containerbase-buildpack:7.10.1@sha256:41a9749c3a5b66ec210cabe64dba275632539adc899e1c14a9c4af1da0f07a50 AS base

# renovate: datasource=github-tags depName=nodejs/node
RUN install-tool node v20.3.0

# renovate: datasource=npm depName=yarn versioning=npm
RUN install-tool yarn 1.22.19

WORKDIR /usr/src/app

# renovate: datasource=github-releases depName=docker lookupName=moby/moby
RUN install-tool docker v24.0.2

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
