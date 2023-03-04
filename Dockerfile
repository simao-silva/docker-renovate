# renovate: datasource=npm depName=renovate versioning=npm
ARG RENOVATE_VERSION=34.157.0

# Base image
#============
FROM simaofsilva/containerbase-buildpack:6.3.5@sha256:739eb51944fb7ed3c7e6def6d1f96363e29b663a832eeb8a5673994c14607937 AS base

# renovate: datasource=github-tags depName=nodejs/node
RUN install-tool node v19.7.0

# renovate: datasource=npm depName=yarn versioning=npm
RUN install-tool yarn 1.22.19

WORKDIR /usr/src/app

# renovate: datasource=github-releases depName=docker lookupName=moby/moby
RUN install-tool docker v23.0.1

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
