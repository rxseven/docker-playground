#!/bin/bash

# Update Docker Compose
sudo rm ${BINARY_PATH}/docker-compose
curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > docker-compose
chmod +x docker-compose
sudo mv docker-compose ${BINARY_PATH}
