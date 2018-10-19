# Dependencies
include .env

# Variables
SHELL := /bin/bash
IMAGE_TAG := rxseven\/playground:${RELEASE_VERSION}

# Default goal
.DEFAULT_GOAL := help

##@ Common:

.PHONY: install
install: ## TODO
	@echo "Cloning the repository..."

##@ Development:

.PHONY: start
start: ## Build, (re)create, start, and attach to containers for a service
	@echo "Starting the development and reverse proxy containers..."
	@docker-compose up

.PHONY: restart
restart: ## Build images before starting the development and reverse proxy containers
	@echo "Restarting the development and reverse proxy containers..."
	@docker-compose up --build

.PHONY: shell
shell: ## Attach an interactive shell to the development container
	@echo "Attaching an interactive shell to the development container"
	@docker container exec -it playground-local sh

.PHONY: test
test: ## Run tests in watch mode
	@echo "Starting the testing container based on the development image..."
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
	@echo "Cleaning up containers and networks"
	@docker-compose down

.PHONY: clean-all
clean-all: ## Stop containers, remove containers, networks, and volumes
	@echo "Cleaning up containers, networks, and volumes"
	@docker-compose down -v

.PHONY: reset
reset: clean-all ## Remove containers, networks, volumes, and the development image
	@echo "Removing all images..."
	@docker image rm local/playground:development

##@ Deployment:

.PHONY: start-production
start-production: ## Create and run the optimized production build
	@echo "Creating the optimized production build..."
	@echo "Starting the production and reverse proxy containers..."
	@docker-compose \
	-f docker-compose.yml \
	-f docker-compose.production.yml \
	up --build

.PHONY: start-production-build
start-production-build: ## Build images before starting the production and reverse proxy containers
	@echo "Creating the optimized production build..."
	@echo "Restarting the production and reverse proxy containers..."
	@docker-compose \
	-f docker-compose.yml \
	-f docker-compose.production.yml \
	up

##@ CI/CD:

.PHONY: ci-update
ci-update: ## Install additional dependencies required for running on the CI environment
	@echo "Installing additional dependencies..."
	@${SCRIPTS_PATH}/update.sh

.PHONY: ci-test
ci-test: ## Run tests and create code coverage reports
	@echo "Running tests and creating code coverage reports..."
	@${SCRIPTS_PATH}/test.sh

##@ Miscellaneous:

.PHONY: ztag
ztag: ## Sandbox
	@sed -i='' "s/<IMAGE_TAG>/${IMAGE_TAG}/" Dockerrun.aws.json

.PHONY: help
help: ## Print usage
	@awk 'BEGIN {FS = ":.*##"; \
	printf "\nUsage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ \
	{ printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2 } /^##@/ \
	{ printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)