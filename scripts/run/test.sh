#!/bin/bash

# Run tests
docker-compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.test.yml run --name playground-test --rm app
