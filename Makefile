# Dependencies
include .env

# Variables
SHELL := /bin/bash
IMAGE_TAG := rxseven\/playground:${RELEASE_VERSION}

# Generate console log
define console
	@printf "\e[${ANSI_COLOR_MAGENTA};1m$(1)\e[0m \n"
endef

# Default goal
.DEFAULT_GOAL := help

##@ Common:

.PHONY: install
install: ## TODO
	@$(call console,Cloning the repository...)

##@ Development:

.PHONY: start
start: ## Build, (re)create, start, and attach to containers for a service
	@$(call console,Starting the development and reverse proxy containers...)
	@docker-compose up

.PHONY: restart
restart: ## Build images before starting the development and reverse proxy containers
	@$(call console,Restarting the development and reverse proxy containers...)
	@docker-compose up --build

.PHONY: shell
shell: ## Attach an interactive shell to the development container
	@$(call console,Attaching an interactive shell to the development container...)
	@docker container exec -it playground-local sh

.PHONY: test
test: ## Run tests in watch mode
	@$(call console,Starting the testing container based on the development image...)
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
	@$(call console,Cleaning up containers and networks...)
	@docker-compose down

.PHONY: clean-all
clean-all: ## Stop containers, remove containers, networks, and volumes
	@$(call console,Cleaning up containers, networks, and volumes...)
	@docker-compose down -v

.PHONY: reset
reset: clean-all ## Remove containers, networks, volumes, and the development image
	@$(call console,Removing all images...)
	@docker image rm local/playground:development

##@ Deployment:

.PHONY: start-production
start-production: ## Create and run the optimized production build
	@$(call console,Creating the optimized production build...)
	@$(call console,Starting the production and reverse proxy containers...)
	@docker-compose \
	-f docker-compose.yml \
	-f docker-compose.production.yml \
	up --build

.PHONY: start-production-build
start-production-build: ## Build images before starting the production and reverse proxy containers
	@$(call console,Creating the optimized production build...)
	@$(call console,Restarting the production and reverse proxy containers...)
	@docker-compose \
	-f docker-compose.yml \
	-f docker-compose.production.yml \
	up

##@ Continuous Integration:

.PHONY: ci-update
ci-update: ## Install additional dependencies required for running on the CI environment
	@$(call console,Installing additional dependencies...)
	@${SCRIPTS_PATH}/update.sh

.PHONY: ci-test
ci-test: ## Run tests and create code coverage reports
	@$(call console,Running tests and creating code coverage reports...)
	@${SCRIPTS_PATH}/test.sh

.PHONY: ci-deploy
ci-deploy: ## Create deployment configuration and build a production image
	@$(call console,Creating deployment configuration and building a production image...)
	@${SCRIPTS_PATH}/deploy.sh

##@ Miscellaneous:

.PHONY: ztag
ztag: ## Sandbox
	@sed -i='' "s/<IMAGE_ACCOUNT>/rxseven/" Dockerrun.aws.json
	@sed -i='' "s/<IMAGE_REPO>/playground/" Dockerrun.aws.json
	@sed -i='' "s/<IMAGE_TAG>/0.0.9/" Dockerrun.aws.json

.PHONY: help
help: ## Print usage
	@awk 'BEGIN {FS = ":.*##"; \
	printf "\nUsage: make \033[${ANSI_COLOR_CYAN}m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ \
	{ printf "  \033[${ANSI_COLOR_CYAN}m%-27s\033[0m %s\n", $$1, $$2 } /^##@/ \
	{ printf "\n\033[0m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
