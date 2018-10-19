#!/bin/bash

# Create deployment configuration
sed -i='' "s/<IMAGE_ACCOUNT>/${BUILD_ACCOUNT}/" ${PRODUCTION_CONFIG}
sed -i='' "s/<IMAGE_REPO>/${BUILD_REPO}/" ${PRODUCTION_CONFIG}
sed -i='' "s/<IMAGE_TAG>/${BUILD_VERSION}/" ${PRODUCTION_CONFIG}
zip ${BUILD_ZIP} ${PRODUCTION_CONFIG}

# Build a production image for deployment
docker-compose -f docker-compose.yml -f docker-compose.production.yml build app

# Login to Docker Hub
echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin

# Push the production image to Docker Hub
docker push rxseven/playground:${BUILD_VERSION}
