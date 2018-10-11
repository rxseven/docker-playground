#!/bin/bash

# Create a zip file containing deployment configuration
zip build.zip Dockerrun.aws.json

# Build a production image for deployment
docker-compose -f docker-compose.yml -f docker-compose.production.yml build

# Login to Docker Hub
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

# Push the production image to Docker Hub
docker push rxseven/playground:0.0.6
