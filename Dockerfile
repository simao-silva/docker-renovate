# renovate: datasource=npm depName=renovate versioning=npm
ARG RENOVATE_VERSION=35.32.0

# Base image
#============
FROM simaofsilva/containerbase-buildpack:7.2.2@sha256:3ff712f89a18c3bba5401054a1746b8c325e1e7a5c389be48c0cc8a44b65f900 AS base

# renovate: datasource=github-tags depName=nodejs/node
RUN install-tool node v19.8.1

# renovate: datasource=npm depName=yarn versioning=npm
RUN install-tool yarn 1.22.19

WORKDIR /usr/src/app

# renovate: datasource=github-releases depName=docker lookupName=moby/moby
RUN install-tool docker v23.0.2

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
