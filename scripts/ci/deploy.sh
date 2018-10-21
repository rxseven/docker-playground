#!/bin/bash

# Create deployment configuration
echo "Creating a deployment config..."
echo "[1/2] Create Dockerrun.aws.json on the fly"
sed -ie 's|\(.*"Name"\): "\(.*\)",.*|\1: '"\"${BUILD_ACCOUNT}\/${BUILD_REPO}:${BUILD_VERSION}\",|" ${PRODUCTION_CONFIG}
echo "[2/2] Zip deployment config"
zip ${BUILD_ZIP} ${PRODUCTION_CONFIG}

# Build a production image for deployment
echo "Building a production image..."
echo "[1/3] Build production image"
docker-compose -f docker-compose.yml -f docker-compose.production.yml build app

# Login to Docker Hub
echo "[2/3] Login to Docker Hub"
echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin

# Push the production image to Docker Hub
echo "[3/3] Push the image to Docker Hub"
docker push rxseven/playground:${BUILD_VERSION}
echo "Done"
