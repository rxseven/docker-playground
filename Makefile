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
logger = @printf "\e[100m make \e[${1};49m $(2)\e[0m \n"
log-info = $(call logger,${ANSI_COLOR_WHITE},$(1));
log-start = $(call logger,${ANSI_COLOR_MAGENTA},$(1));
log-step = $(call logger,${ANSI_COLOR_YELLOW},$(1));
log-success = $(call logger,${ANSI_COLOR_GREEN},$(1));
newline = @echo ""

# Test script
define script-test
	# Run a container for testing, run tests, and generate code coverage reports
	@$(call log-step,[Step 1/4] Create and start a container for running tests)
	@$(call log-step,[Step 2/4] Run tests and generate code coverage reports)
	docker-compose -f docker-compose.yml -f docker-compose.ci.yml up app

	# Copy LCOV data from the container's file system to the CI's
	@$(call log-step,[Step 3/4] Copy LCOV data from the container's file system to the CI's)
	docker cp app-ci:${CONTAINER_WORKDIR}/coverage ./

	# Replace container's working directory path with the CI's
	@$(call log-step,[Step 4/4] Fix source paths in the LCOV file)
	yarn replace ${CONTAINER_WORKDIR} ${TRAVIS_BUILD_DIR} ${LCOV_DATA} --silent
endef

# Dependencies installation script
define script-update
	# Update Docker Compose
	@$(call log-step,[Step 1/1] Update Docker Compose to version ${DOCKER_COMPOSE_VERSION})
	sudo rm ${BINARY_PATH}/docker-compose
	curl -L ${DOCKER_COMPOSE_REPO}/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > docker-compose
	chmod +x docker-compose
	sudo mv docker-compose ${BINARY_PATH}
endef

# Deployment script
define script-deploy
	# Create deployment configuration
	echo "Creating a deployment configuration"
	$(call log-step,[Step 1/2] Create ${PRODUCTION_CONFIG} for AWS Elastic Beanstalk deployment)
	sed -ie 's|\(.*"Name"\): "\(.*\)",.*|\1: '"\"${BUILD_ACCOUNT}\/${BUILD_REPO}:${BUILD_VERSION}\",|" ${PRODUCTION_CONFIG}
	echo "[2/2] Create ${BUILD_ZIP} for uploading to AWS S3 service"
	zip ${BUILD_ZIP} ${PRODUCTION_CONFIG}

	# Build a production image for deployment
	echo "Building a production image for deployment..."
	$(call log-step,[Step 1/3] Build the image)
	docker-compose -f docker-compose.yml -f docker-compose.production.yml build app

	# Login to Docker Hub
	$(call log-step,[Step 2/3] Login to Docker Hub)
	echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin

	# Push the production image to Docker Hub
	$(call log-step,[Step 3/3] Push the image to Docker Hub)
	docker push rxseven/playground:${BUILD_VERSION}
	echo "Done"
endef

# Set configuration property
set-property = @sed -ie 's|\(.*"$(1)"\): "\(.*\)",.*|\1: '"\"$(2)\",|" $(3)

# Default goal
.DEFAULT_GOAL := help

##@ Common:

.PHONY: install
install: ## TODO
	@$(call log-start,Cloning the repository...)

##@ Development:

.PHONY: start
start: ## Build, (re)create, start, and attach to containers for a service
	@$(call log-start,Starting the development environment...)
	@$(call log-step,[Step 1/3] Build images (if needed))
	@$(call log-step,[Step 2/3] Run the development and reverse proxy containers)
	@$(call log-step,[Step 3/3] Start the development server)
	@$(call log-info,You can view ${APP_NAME} in the browser at ${APP_URL})
	@docker-compose up

.PHONY: restart
restart: ## Build images before starting the development and reverse proxy containers
	@$(call log-start,Restarting the development and reverse proxy containers...)
	@docker-compose up --build

.PHONY: shell
shell: ## Attach an interactive shell to the development container
	@$(call log-start,Attaching an interactive shell to the development container...)
	@docker container exec -it playground-local sh

.PHONY: test
test: ## Run tests in watch mode
	@$(call log-start,Starting the testing container based on the development image...)
	@docker-compose \
	-f docker-compose.yml \
	-f docker-compose.override.yml \
	-f docker-compose.test.yml run \
	--name playground-test \
	--rm \
	app

##@ Cleanup:

.PHONY: clean
clean: ## Stop containers, remove containers and networks
	@$(call log-start,Cleaning up containers and networks...)
	@docker-compose down

.PHONY: clean-all
clean-all: ## Stop containers, remove containers, networks, and volumes
	@$(call log-start,Cleaning up containers$(,) networks$(,) and volumes...)
	@docker-compose down -v
	@$(call log-success,Cleaned up successfully.)

.PHONY: reset
reset: ## Remove containers, networks, volumes, and the development image
	@$(call log-start,Removing unused data...)
	@$(call log-step,[Step 1/4] Remove containers$(,) networks$(,) and volumes...)
	-@docker-compose down -v
	@$(call log-step,[Step 2/4] Remove the development image)
	-@docker image rm local/playground:development
	@$(call log-step,[Step 3/4] Remove the production image)
	-@docker image rm ${IMAGE_NAME}
	@$(call log-step,[Step 4/4] Remove the intermediate images)
	-@docker image prune --filter label=stage=intermediate --force
	@$(call log-success,Done)

##@ Production:

.PHONY: start-production
start-production: ## Run the production build
	@$(call log-start,Running the production build...)
	@$(call log-step,[Step 1/3] Create an optimized production build)
	@$(call log-step,[Step 2/4] Build an image (if needed))
	@$(call log-step,[Step 3/4] Run a production container)
	@$(call log-step,[Step 4/4] Start the web server serving the production build)
	@docker-compose \
	-f docker-compose.yml \
	-f docker-compose.production.yml \
	up

.PHONY: start-production-build
start-production-build: ## Build an image and run the production build
	@$(call log-start,Build an image and run the production build...)
	@docker-compose \
	-f docker-compose.yml \
	-f docker-compose.production.yml \
	up --build

##@ Release & Deployment

.PHONY: release
release: ## TODO: Set release version to package.json, .travis.yml, .env
	@$(call log-start,TODO: Set release version)

##@ Continuous Integration:

.PHONY: ci-update
ci-update: ## Install additional dependencies required for running on the CI environment
	@$(call log-start,Installing additional dependencies...)
	@$(script-update)

.PHONY: ci-test
ci-test: ## Run tests and create code coverage reports
	@$(call log-start,Running tests and creating code coverage reports...)
	@$(script-test)

.PHONY: ci-deploy
ci-deploy: ## Create deployment configuration and build a production image
	@$(call log-start,Creating deployment configuration and building a production image...)
	@${script-deploy}

.PHONY: ci-coveralls
ci-coveralls: ## Send LCOV data (code coverage reports) to coveralls.io
	@$(call log-start,Sending LCOV data to coveralls.io...)
	@$(call log-step,[Step 1/2] Collect LCOV data from /coverage/lcov.info)
	@$(call log-step,[Step 2/2] Send the data to coveralls.io)
	@cat ${LCOV_DATA} | coveralls

.PHONY: ci-clean
ci-clean: ## Remove unused data from the CI server
	@$(call log-start,Removing unused data...)
	@docker system prune --all --volumes --force

##@ Miscellaneous:

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
	@cat Dockerrun.aws.json
	@sed -ie 's|\(.*"Name"\): "\(.*\)",.*|\1: '"\"${IMAGE_NAME}\",|" ${CONFIG_FILE_AWS}
	@cat Dockerrun.aws.json