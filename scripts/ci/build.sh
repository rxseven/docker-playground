#!/bin/bash

# Logs
cat ${CI_PRODUCTION_CONFIG}

# Create deployment configuration
sed -ie 's|\(.*"Name"\): "\(.*\)",.*|\1: '"\"${CI_BUILD_ACCOUNT}\/${CI_BUILD_REPO}:${CI_BUILD_VERSION}\",|" ${CI_PRODUCTION_CONFIG}
zip ${CI_BUILD_ZIP} ${CI_PRODUCTION_CONFIG}

# Logs
cat ${CI_PRODUCTION_CONFIG}

# Build a production image for deployment
docker-compose -f docker-compose.yml -f docker-compose.production.yml build app

# Login to Docker Hub
echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin

# Push the production image to Docker Hub
# docker push rxseven/playground:${CI_BUILD_VERSION}

# Logs
docker image ls
