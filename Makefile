# Dependencies
include .env

# Escape
, := ,
blank :=
space := $(blank) $(blank)

# Variables
SHELL := /bin/bash

# ANSI Colors
ANSI_COLOR_BLACK=30
ANSI_COLOR_BLUE=34
ANSI_COLOR_CYAN=36
ANSI_COLOR_GREEN=32
ANSI_COLOR_MAGENTA=35
ANSI_COLOR_RED=31
ANSI_COLOR_YELLOW=33
ANSI_COLOR_WHITE=37

# Logger
logger = printf "\e[100m make \e[${1};49m $(2)\e[0m \n"
log-info = $(call logger,${ANSI_COLOR_WHITE},$(1));
log-start = $(call logger,${ANSI_COLOR_MAGENTA},$(1));
log-step = $(call logger,${ANSI_COLOR_YELLOW},$(1));
log-success = $(call logger,${ANSI_COLOR_GREEN},$(1));
log-sum = $(call logger,${ANSI_COLOR_CYAN},$(1));
newline = echo ""
txt-bold = \e[1m$(1)\e[0m

# Set configuration values
set-json = sed -i.backup 's|\(.*"$(1)"\): "\(.*\)"$(3).*|\1: '"\"$(2)\"$(3)|" $(4)
set-env = sed -i.backup 's;^$(1)=.*;$(1)='"$(2)"';' $(3)

# Hosts script
script-host = echo "${HOST_IP}       $(1)" | sudo tee -a ${HOST_CONFIG}

# Test script
define script-test
	# Run a container for testing, run tests, and generate code coverage reports
	$(call log-step,[Step 1/3] Build an image based on the development environment)
	$(call log-step,[Step 2/3] Create and start a container for running tests)
	$(call log-step,[Step 3/3] Run tests and generate code coverage reports)
	docker-compose -f docker-compose.yml -f docker-compose.ci.yml up app
endef

# Creating LCOV data script
define script-coverage
	# Copy LCOV data from the container's file system to the CI's
	$(call log-step,[Step 1/2] Copy LCOV data from the container\'s file system to the CI\'s)
	docker cp app-ci:${CONTAINER_WORKDIR}/coverage ./

	# Replace container's working directory path with the CI's
	$(call log-step,[Step 2/2] Fix source paths in the LCOV file)
	yarn replace ${CONTAINER_WORKDIR} ${TRAVIS_BUILD_DIR} ${LCOV_DATA} --silent
endef

# Dependencies installation script
define script-update
	# Update Docker Compose
	$(call log-step,[Step 1/1] Update Docker Compose to version ${DOCKER_COMPOSE_VERSION})
	sudo rm ${BINARY_PATH}/docker-compose
	curl -L ${DOCKER_COMPOSE_REPO}/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > docker-compose
	chmod +x docker-compose
	sudo mv docker-compose ${BINARY_PATH}
endef

# Release script
define script-release
	$(call log-step,[Step 1/2] Configure ${CONFIG_FILE_AWS} for AWS Elastic Beanstalk deployment)
	$(call set-json,Name,${IMAGE_NAME},$(,),${CONFIG_FILE_AWS})
	$(call set-json,ContainerPort,${PORT_EXPOSE_PROXY},$(blank),${CONFIG_FILE_AWS})
	$(call log-step,[Step 2/2] Configure ${CONFIG_FILE_NPM} for AWS Node.js deployment)
	$(call set-json,version,${RELEASE_VERSION},$(,),${CONFIG_FILE_NPM})
	
	# Remove .backup files after performing text transformations
	rm *.backup
endef

# Predeploy script
define script-predeploy
	# Configure a deployment configuration
	$(call log-start,Configuring a deployment configuration...)
	$(script-release)

	# Build a deployment configuration
	$(call log-start,Building a deployment configuration...)
	$(call log-step,[Step 1/1] Build ${BUILD_ZIP} for uploading to AWS S3 service)
	zip ${BUILD_ZIP} ${CONFIG_FILE_AWS}
endef

# Deployment script
define script-deploy
	# Build a production image for deployment
	$(call log-start,Building a production image (version ${RELEASE_VERSION}) for deployment...)
	$(call log-step,[Step 1/3] Build the image)
	docker-compose -f docker-compose.yml -f docker-compose.production.yml build app

	# Login to Docker Hub
	$(call log-step,[Step 2/3] Login to Docker Hub)
	echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin

	# Push the production image to Docker Hub
	$(call log-step,[Step 3/3] Push the image to Docker Hub)
	docker push ${IMAGE_NAME}
endef

# Default goal
.DEFAULT_GOAL := help

##@ Common:

.PHONY: setup
setup: ## Setup the development environment and install required dependencies
	@$(call log-start,Setting up the project...)
	@$(call log-step,[Step 1/2] Install dependencies required for running on the development environment)
	@docker pull ${IMAGE_BASE_NGINX}
	@docker pull ${IMAGE_BASE_NODE}
	@docker pull ${IMAGE_BASE_PROXY}
	@$(call log-step,[Step 2/2] Set a custom domain for a self-signed SSL certificate)
	@$(call script-host,${APP_HOST_LOCAL})
	@$(call script-host,${APP_HOST_BUILD})
	@$(call log-success,Done)

##@ Development:

.PHONY: start
start: ## Build, (re)create, start, and attach to containers for a service
	@$(call log-start,Starting the development environment...)
	@$(call log-step,[Step 1/3] Download base images and build the development image (if needed))
	@$(call log-step,[Step 2/3] Create and start the development and reverse proxy containers)
	@$(call log-step,[Step 3/3] Start the development server)
	@$(call log-info,You can view ${APP_NAME} in the browser at ${APP_URL_LOCAL})
	@docker-compose up

.PHONY: restart
restart: ## Build images before starting the development and reverse proxy containers
	@$(call log-start,Restarting the development environment...)
	@$(call log-step,[Step 1/3] Rebuild the development image)
	@$(call log-step,[Step 2/3] Create and start the development and reverse proxy containers)
	@$(call log-step,[Step 3/3] Start the development server)
	@docker-compose up --build

.PHONY: shell
shell: ## Attach an interactive shell to the development container
	@$(call log-start,Attaching an interactive shell to the development container...)
	@docker container exec -it playground-local sh

.PHONY: test
test: ## Run tests in watch mode
	@$(call log-start,Running tests...)
	@$(call log-step,[Step 1/3] Download base images (if needed))
	@$(call log-step,[Step 2/3] Build the development image (if needed))
	@$(call log-step,[Step 3/3] Create and start a container for running tests in watch mode)
	@docker-compose \
	-f docker-compose.yml \
	-f docker-compose.override.yml \
	-f docker-compose.test.yml run \
	--name playground-test \
	--rm \
	app

.PHONY: build
build: ## Create an optimized production build
	@$(call log-start,Creating an optimized production build...)
	@$(call log-step,[Step 1/6] Remove an existing build (if necessary))
	@rm -rf -v ${DIRECTORY_BUILD}
	@$(call log-step,[Step 2/6] Download base images (if needed))
	@$(call log-step,[Step 3/6] Build the development image (if needed))
	@$(call log-step,[Step 4/6] Create and start a container for building the app)
	@$(call log-step,[Step 5/6] Create an optimized production build)
	@$(call log-step,[Step 6/6] Stop and remove the container)
	@docker-compose run --rm app build
	@$(call log-info,The production build has been created successfully in $(call txt-bold,./${DIRECTORY_BUILD}) directory)
	@ls ${DIRECTORY_BUILD}
	@$(call log-success,Done)

.PHONY: preview
preview: ## Preview the production build locally
	@$(call log-start,Running the production build...)
	@$(call log-step,[Step 1/6] Remove intermediate and unused images (when necessary))
	-@docker image prune --filter label=stage=intermediate --force
	@$(call log-step,[Step 2/6] Download base images (if needed))
	@$(call log-step,[Step 3/6] Create an optimized production build)
	@$(call log-step,[Step 4/6] Build the production image tagged $(call txt-bold,${IMAGE_NAME}))
	@$(call log-step,[Step 5/6] Create and start the app and reverse proxy containers)
	@$(call log-step,[Step 6/6] Start the web (for serving the app) and reverse proxy servers)
	@$(call log-info,You can view $(call txt-bold,${APP_NAME}) in the browser at ${APP_URL_BUILD})
	@docker-compose \
	-f docker-compose.yml \
	-f docker-compose.production.yml \
	up --build

##@ Cleanup:

.PHONY: clean
clean: ## Stop containers, remove containers and networks
	@$(call log-start,Cleaning up containers and networks...)
	@docker-compose down
	@$(call log-sum,[sum] Containers (including exited state))
	@docker container ls -a
	@$(call log-sum,[sum] Networks)
	@docker network ls
	@$(call log-success,Done)

.PHONY: clean-all
clean-all: ## Stop containers, remove containers, networks, and volumes
	@$(call log-start,Cleaning up containers$(,) networks$(,) and volumes...)
	@docker-compose down -v
	@$(call log-sum,[sum] Containers (including exited state))
	@docker container ls -a
	@$(call log-sum,[sum] Networks)
	@docker network ls
	@$(call log-sum,[sum] Volumes)
	@docker volume ls
	@$(call log-success,Done)

.PHONY: reset
reset: ## Remove containers, networks, volumes, and the development image
	@$(call log-start,Removing unused data...)
	@$(call log-step,[Step 1/6] Remove containers$(,) networks$(,) and volumes...)
	-@docker-compose down -v
	@$(call log-sum,[sum] Containers (including exited state))
	@docker container ls -a
	@$(call log-sum,[sum] Networks)
	@docker network ls
	@$(call log-sum,[sum] Volumes)
	@docker volume ls
	@$(call log-step,[Step 2/6] Remove the development image)
	-@docker image rm local/playground:development
	@$(call log-step,[Step 3/6] Remove the production image)
	-@docker image rm ${IMAGE_NAME}
	@$(call log-step,[Step 4/6] Remove the intermediate images)
	-@docker image prune --filter label=stage=intermediate --force
	@$(call log-step,[Step 5/6] Remove all unused images (optional))
	-@docker image prune
	@$(call log-sum,[sum] Images (including intermediates))
	@docker image ls -a
	@$(call log-step,[Step 6/6] Remove the build artifacts)
	@rm -rf -v build coverage
	@$(call log-success,Done)

##@ Release & Deployment

.PHONY: version
version: ## Set the next release version
	@$(call log-start,Set the next release version)
	@read -p "Enter a version number: " VERSION; \
	if [ "$$VERSION" != "" ]; then \
		echo "Your next release will be v$$VERSION"; \
		$(call set-env,RELEASE_DATE,$$(date +'%d.%m.%Y'),${CONFIG_FILE_ENV}); \
		$(call set-env,RELEASE_VERSION,$$VERSION,${CONFIG_FILE_ENV}); \
		rm ${CONFIG_FILE_ENV}.backup; \
	else \
		echo "You did not enter a version number, please try again"; \
	fi;
	@$(call log-success,Done)

.PHONY: release
release: ## Release new features
	@$(call log-start,Release new features)
	@$(script-release)
	@$(call log-success,Done)

##@ Continuous Integration:

.PHONY: ci-update
ci-update: ## Install additional dependencies required for running on the CI environment
	@$(call log-start,Installing additional dependencies...)
	@$(script-update)
	@$(call log-success,Done)

.PHONY: ci-setup
ci-setup: ## Setup the CI environment and install required dependencies
	@$(call log-start,Setting up the CI environment...)
	@$(call log-step,[Step 1/2] Install dependencies required for running on the CI environment)
	@docker pull ${IMAGE_BASE_NGINX}
	@docker pull ${IMAGE_BASE_NODE}
	@$(call log-step,[Step 2/2] List downloaded Docker images)
	@docker image ls
	@$(call log-success,Done)

.PHONY: ci-test
ci-test: ## Run tests and generate code coverage reports
	@$(call log-start,Running tests...)
	@$(script-test)
	@$(call log-success,Done)

.PHONY: ci-coverage
ci-coverage: ## Create code coverage reports (LCOV format)
	@$(call log-start,Creating code coverage reports...)
	@$(script-coverage)
	@$(call log-success,Done)

.PHONY: ci-deploy
ci-deploy: ## Create deployment configuration and build a production image
	@${script-predeploy}
	@${script-deploy}
	@$(call log-success,Done)

.PHONY: ci-coveralls
ci-coveralls: ## Send LCOV data (code coverage reports) to coveralls.io
	@$(call log-start,Sending LCOV data to coveralls.io...)
	@$(call log-step,[Step 1/2] Collect LCOV data from /coverage/lcov.info)
	@$(call log-step,[Step 2/2] Send the data to coveralls.io)
	@cat ${LCOV_DATA} | coveralls
	@$(call log-success,Done)

.PHONY: ci-clean
ci-clean: ## Remove unused data from the CI server
	@$(call log-start,Removing unused data...)
	@docker system prune --all --volumes --force
	@$(call log-success,Done)

.PHONY: ci-check
ci-check: ## Check CI (won't work on Travis CI)
	@sed -i '' 's|\(.*"Name"\): "\(.*\)",.*|\1: '"\"${IMAGE_NAME}\",|" ${CONFIG_FILE_AWS}

##@ Miscellaneous:

.PHONY: info
info: ## Show project information
	@$(call log-start,Show project information)
	@echo "Release date : ${RELEASE_DATE}"

.PHONY: help
help: ## Print usage
	@awk 'BEGIN {FS = ":.*##"; \
	printf "\nUsage: make \033[${ANSI_COLOR_CYAN}m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ \
	{ printf "  \033[${ANSI_COLOR_CYAN}m%-27s\033[0m %s\n", $$1, $$2 } /^##@/ \
	{ printf "\n\033[0m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: yo
yo: ## Yo
	@$(call log-step,yo-text-here)

.PHONY: try-aws
try-aws: ## Try AWS
	@$(call log-start,Trying to update Dockerrun.aws.json...)
	@cat Dockerrun.aws.json
	@sed -ie 's|\(.*"Name"\): "\(.*\)",.*|\1: '"\"${IMAGE_NAME}\",|" ${CONFIG_FILE_AWS}
	@cat Dockerrun.aws.json

.PHONY: try-env
try-env: ## Try ENV
	@$(call log-start,Trying to log ENV from .env...)
	@echo "RELEASE_DATE = ${RELEASE_DATE}"
	@echo "RELEASE_VERSION = ${RELEASE_VERSION}"
	@echo "APP_NAME = ${APP_NAME}"
	@echo "APP_DOMAIN = ${APP_DOMAIN}"
	@echo "APP_TLD = ${APP_TLD}"
	@echo "APP_URL_PROTOCAL = ${APP_URL_PROTOCAL}"
	@echo "APP_HOST_LOCAL = ${APP_HOST_LOCAL}"
	@echo "APP_HOST_BUILD = ${APP_HOST_BUILD}"
	@echo "APP_URL_LOCAL = ${APP_URL_LOCAL}"
	@echo "APP_URL_BUILD = ${APP_URL_BUILD}"
	@echo "IMAGE_BASE_NGINX = ${IMAGE_BASE_NGINX}"
	@echo "IMAGE_BASE_NODE = ${IMAGE_BASE_NODE}"
	@echo "IMAGE_BASE_PROXY = ${IMAGE_BASE_PROXY}"
	@echo "IMAGE_NAME = ${IMAGE_NAME}"
	@echo "IMAGE_REPO = ${IMAGE_REPO}"
	@echo "IMAGE_USERNAME = ${IMAGE_USERNAME}"
	@echo "WORKDIR = ${WORKDIR}"
	@echo "CONFIG_FILE_CI = ${CONFIG_FILE_CI}"
	@echo "CONFIG_FILE_NPM = ${CONFIG_FILE_NPM}"
	@echo "CONFIG_FILE_AWS = ${CONFIG_FILE_AWS}"