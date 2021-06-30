#################################
#          Build Stage          #
#################################

FROM ruby:2.7 AS build

# Set build shell
SHELL ["/bin/bash", "-c"]

# Use root user
USER root

ARG BUILD_PACKAGES
ARG BUILD_SCRIPT
ARG BUNDLE_WITHOUT='development:metrics:test'
ARG BUNDLER_VERSION=2.2.17
ARG POST_BUILD_SCRIPT
ARG SKIP_MEMCACHE_CHECK=true
ARG RAILS_ENV=production
ARG SECRET_KEY_BASE

# Install dependencies
RUN    apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y ${BUILD_PACKAGES}

RUN [[ ${BUILD_SCRIPT} ]] && bash -c "${BUILD_SCRIPT}"

# Install specific versions of dependencies
RUN gem install bundler:${BUNDLER_VERSION} --no-document

# TODO: Load artifacts

# set up app-src directory
COPY . /app-src
WORKDIR /app-src

# Run deployment
RUN    bundle config set --local deployment 'true' \
  && bundle config set --local without ${BUNDLE_WITHOUT} \
  && bundle package \
  && bundle install \
  && bundle clean

RUN [[ ${POST_BUILD_SCRIPT} ]] && bash -c "${POST_BUILD_SCRIPT}"

# TODO: Save artifacts

RUN rm -rf vendor/cache/ .git

#################################
#           Run Stage           #
#################################

# Set runtime shell
SHELL ["/bin/bash", "-c"]

# Add user
RUN adduser --disabled-password --uid 1001 --gid 0 --gecos "" app

ARG BUNDLE_WITHOUT='development:metrics:test'
ARG BUNDLER_VERSION=2.2.17
ARG RUN_PACKAGES

# Install dependencies, remove apt!
RUN    apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y ${RUN_PACKAGES} \
  vim-tiny curl

WORKDIR /app-src

# Set group permissions to app folder
RUN    chgrp -R 0 /app-src \
  && chmod -R u+w,g=u /app-src

ENV HOME=/app-src

# Use cached gems
RUN    bundle config set --local deployment 'true' \
  && bundle config set --local without ${BUNDLE_WITHOUT} \
  && bundle

# Clean APT

USER 1001

CMD ["bundle", "exec", "puma", "-t", "8"]