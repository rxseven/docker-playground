#!/bin/bash

# Run a container for testing, run tests, and generate code coverage reports
docker-compose -f docker-compose.yml -f docker-compose.ci.yml up

# Copy LCOV data from the container's file system to the CI's
docker cp app-ci:${CONTAINER_WORKDIR}/coverage ./

# Replace container's working directory path with the CI's
yarn replace ${CONTAINER_WORKDIR} ${TRAVIS_BUILD_DIR} ${LCOV_DATA}
