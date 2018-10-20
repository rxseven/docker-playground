#!/bin/bash

# Run a container for testing, run tests, and generate code coverage reports
docker-compose -f docker-compose.yml -f docker-compose.ci.yml up app

# Copy LCOV data from the container's file system to the CI's
docker cp app-ci:${CI_CONTAINER_WORKDIR}/coverage ./

# Replace container's working directory path with the CI's
yarn replace ${CI_CONTAINER_WORKDIR} ${TRAVIS_BUILD_DIR} ${CI_LCOV_DATA} --silent
