# Dependencies
include .env

# Variables
SHELL := /bin/bash
, := ,
blank :=
space := $(blank) $(blank)

# ANSI Colors
ANSI_COLOR_BLACK=30
ANSI_COLOR_BLUE=34
ANSI_COLOR_CYAN=36
ANSI_COLOR_GREEN=32
ANSI_COLOR_MAGENTA=35
ANSI_COLOR_RED=31
ANSI_COLOR_YELLOW=33
ANSI_COLOR_WHITE=37

# Default goal
.DEFAULT_GOAL := help

# Logger
logger = printf "\e[100m make \e[${1};49m $(2)\e[0m \n"
log-info = $(call logger,${ANSI_COLOR_WHITE},$(1));
log-start = $(call logger,${ANSI_COLOR_MAGENTA},$(1));
log-step = $(call logger,${ANSI_COLOR_YELLOW},$(1));
log-success = $(call logger,${ANSI_COLOR_GREEN},$(1));
log-sum = $(call logger,${ANSI_COLOR_CYAN},$(1));
newline = echo ""
txt-bold = \e[1m$(1)\e[0m
txt-headline = printf "\e[${ANSI_COLOR_CYAN};49;1m$(1)\e[0m \n\n"

# Set configuration values
set-json = sed -i.${EXT_BACKUP} 's|\(.*"$(1)"\): "\(.*\)"$(3).*|\1: '"\"$(2)\"$(3)|" $(4)
set-env = sed -i.${EXT_BACKUP} 's;^$(1)=.*;$(1)='"$(2)"';' $(3)

# Hosts script
script-host = echo "${HOST_IP}       $(1)" | sudo tee -a ${HOST_DNS}

# Test script
define script-test
	$(call log-step,[Step 1/4] Build the development image (if needed)) \
	$(call log-step,[Step 2/4] Create and start a container for running tests) \
	$(call log-step,[Step 3/4] Run tests) \
	$(call log-step,[Step 4/4] Remove the container when the process finishes) \
	docker-compose \
	-f ${COMPOSE_BASE} \
	-f ${COMPOSE_DEVELOPMENT} \
	-f ${COMPOSE_TEST} run \
	--name ${IMAGE_REPO}-${CONTAINER_SUFFIX_TEST} \
	--rm \
	${SERVICE_APP} test$(1)
endef

# Linting script
define script-lint
	$(call log-step,[Step 1/4] Build the development image (if needed)) \
	$(call log-step,[Step 2/4] Create and start a container for running code linting) \
	$(call log-step,[Step 3/4] Run linting) \
	$(call log-step,[Step 4/4] Remove the container when the process finishes) \
	docker-compose run --rm ${SERVICE_APP} lint$(1)
endef

# Static type checking script
define script-typecheck
	$(call log-step,[Step 1/4] Build the development image (if needed)) \
	$(call log-step,[Step 2/4] Create and start a container for running static type checking) \
	$(call log-step,[Step 3/4] Run static type checking) \
	$(call log-step,[Step 4/4] Remove the container when the process finishes) \
	docker-compose run --rm ${SERVICE_APP} type$(1)
endef

# Creating LCOV data script
define script-coverage
	# Copy LCOV data from the container's file system to the CI's
	$(call log-step,[Step 1/2] Copy LCOV data from the container\'s file system to the CI\'s)
	docker cp ${CONTAINER_NAME_CI}:${CONTAINER_WORKDIR}/${DIR_COVERAGE} ${DIR_ROOT}

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
	$(call log-step,[Step 1/2] Configure ${CONFIG_AWS} for AWS Elastic Beanstalk deployment)
	$(call set-json,Name,${IMAGE_NAME},$(,),${CONFIG_AWS})
	$(call set-json,ContainerPort,${PORT_EXPOSE_PROXY},$(blank),${CONFIG_AWS})
	$(call log-step,[Step 2/2] Configure ${CONFIG_FILE_NPM} for AWS Node.js deployment)
	$(call set-json,version,${RELEASE_VERSION},$(,),${CONFIG_FILE_NPM})
	
	# Remove backup files after performing text transformations
	rm *.${EXT_BACKUP}
endef

# Predeploy script
define script-predeploy
	# Configure a deployment configuration
	$(call log-start,Configuring a deployment configuration...)
	$(script-release)

	# Build a deployment configuration
	$(call log-start,Building a deployment configuration...)
	$(call log-step,[Step 1/1] Build ${BUILD_ZIP} for uploading to AWS S3 service)
	zip ${BUILD_ZIP} ${CONFIG_AWS}
endef

# Deployment script
define script-deploy
	# Build a production image for deployment
	$(call log-start,Building a production image (version ${RELEASE_VERSION}) for deployment...)
	$(call log-step,[Step 1/3] Build the image)
	docker-compose -f ${COMPOSE_BASE} -f ${COMPOSE_PRODUCTION} build ${SERVICE_APP}

	# Login to Docker Hub
	$(call log-step,[Step 2/3] Login to Docker Hub)
	echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin

	# Push the production image to Docker Hub
	$(call log-step,[Step 3/3] Push the image to Docker Hub)
	docker push ${IMAGE_NAME}
endef

##@ Development:

.PHONY: start
start: ## Start the development environment and attach to containers for a service
	@$(call log-start,Starting the development environment...)
	@$(call log-step,[Step 1/4] Download base images (if needed))
	@$(call log-step,[Step 2/4] Build the development image (if needed))
	@$(call log-step,[Step 3/4] Create and start the development and reverse proxy containers)
	@$(call log-step,[Step 4/4] Start the development and reverse proxy servers)
	@$(call log-info,You can view ${APP_NAME} in the browser at ${APP_URL_LOCAL})
	@docker-compose up

.PHONY: restart
restart: ## Rebuild and restart the development environment
	@$(call log-start,Restarting the development environment...)
	@$(call log-step,[Step 1/3] Rebuild the development image)
	@$(call log-step,[Step 2/3] Create and start the development and reverse proxy containers)
	@$(call log-step,[Step 3/3] Start the development and reverse proxy servers)
	@$(call log-info,You can view ${APP_NAME} in the browser at ${APP_URL_LOCAL})
	@docker-compose up --build

.PHONY: shell
shell: ## Attach an interactive shell to the development container
	@$(call log-start,Attaching an interactive shell to the development container...)
	@docker container exec -it ${IMAGE_REPO}-${CONTAINER_SUFFIX_LOCAL} sh

.PHONY: build
build: ## Create an optimized production build
	@$(call log-start,Creating an optimized production build...)
	@$(call log-step,[Step 1/6] Remove the existing build (if one exists))
	-@rm -rf -v ${DIR_BUILD}
	@$(call log-step,[Step 2/6] Download base images (if needed))
	@$(call log-step,[Step 3/6] Build the development image (if it doesn't exist))
	@$(call log-step,[Step 4/6] Create and start a container for building the app)
	@$(call log-step,[Step 5/6] Create an optimized production build)
	@$(call log-step,[Step 6/6] Stop and remove the container)
	@docker-compose run --rm ${SERVICE_APP} build
	@$(call log-info,The production build has been created successfully in $(call txt-bold,./${DIR_BUILD}) directory)
	@ls ${DIR_BUILD}
	@$(call log-success,Done)

.PHONY: install
install: ## Install a package and any packages that it depends on
	@read -p "Enter package name: " package; \
	if [ "$$package" != "" ]; then \
		$(call log-step,[Step 1/5] Build the development image (if needed)) \
		$(call log-step,[Step 2/5] Create and start a container for installing dependencies) \
		$(call log-step,[Step 3/5] Install $$package package in the persistent storage (volume)) \
		$(call log-step,[Step 4/5] Update package.json and yarn.lock) \
		$(call log-step,[Step 5/5] Remove the container) \
		docker-compose run --rm ${SERVICE_APP} add $$package; \
		$(call log-success,Done) \
	else \
		echo "You did not enter the package name, please try again"; \
	fi;

.PHONY: format
format: ## Format code automatically
	@$(call log-start,TODO...)

.PHONY: analyze
analyze: CONTAINER_NAME = ${IMAGE_REPO}-analyzing
analyze: build ## Analyze and debug code bloat through source maps
	@$(call log-start,Analyzing and debugging code...)
	@$(call log-step,[Step 1/5] Create and start a container for analyzing the bundle)
	@$(call log-step,[Step 2/5] Analyze the bundle size)
	@docker-compose run --name ${CONTAINER_NAME} ${SERVICE_APP} analyze
	@$(call log-step,[Step 3/5] Copy the result from the container's file system to the host's)
	@docker cp ${CONTAINER_NAME}:${CONTAINER_TEMP}/. ${HOST_TEMP}
	@$(call log-step,[Step 4/5] Remove the container)
	@docker container rm ${CONTAINER_NAME}
	@$(call log-step,[Step 5/5] Open the treemap visualization in the browser)
	@open -a ${BROWSER_DEFAULT} ${HOST_TEMP}/${FILE_TREEMAP}
	@$(call log-success,Done)

.PHONY: preview
preview: ## Preview the production build locally
	@$(call log-start,Running the production build...)
	@$(call log-step,[Step 1/6] Remove intermediate and unused images (when necessary))
	-@docker image prune --filter label=stage=${IMAGE_LABEL_INTERMEDIATE} --force
	@$(call log-step,[Step 2/6] Download base images (if needed))
	@$(call log-step,[Step 3/6] Create an optimized production build)
	@$(call log-step,[Step 4/6] Build the production image tagged $(call txt-bold,${IMAGE_NAME}))
	@$(call log-step,[Step 5/6] Create and start the app and reverse proxy containers)
	@$(call log-step,[Step 6/6] Start the web (for serving the app) and reverse proxy servers)
	@$(call log-info,You can view $(call txt-bold,${APP_NAME}) in the browser at ${APP_URL_BUILD})
	@docker-compose \
	-f ${COMPOSE_BASE} \
	-f ${COMPOSE_PRODUCTION} \
	up --build

.PHONY: status
status: ## Show system status
	@$(call log-sum,[status] Images (including intermediates))
	@docker image ls -a
	@$(call log-sum,[status] Containers (including exited state))
	@docker container ls -a
	@$(call log-sum,[status] Networks)
	@docker network ls
	@$(call log-sum,[status] Volumes)
	@docker volume ls
	@$(call log-sum,[status] Working copy)
	@git status

##@ Testing and Linting:

.PHONY: test
test: ## Run tests
	@echo "Available modes:"
	@echo "- Watch mode    : press enter"
	@echo "- Code coverage : coverage"
	@echo "- Silent        : sum"
	@echo "- Details       : details"
	@$(newline)
	@read -p "Enter test mode: " mode; \
	if [ "$$mode" == "coverage" ]; then \
		$(call script-test,:coverage); \
		$(call log-sum,[sum] LCOV data is created in ${DIR_ROOT}${DIR_COVERAGE} directory) \
		ls ${DIR_COVERAGE}; \
	else \
		$(call script-test); \
	fi;

.PHONY: lint
lint: ## Run code linting
	@echo "Available options:"
	@echo "- JavaScript        : press enter"
	@echo "- JavaScript (fix)  : fix"
	@echo "- Stylesheet        : stylesheet"
	@$(newline)
	@read -p "Enter the option: " option; \
	if [ "$$option" == "stylesheet" ]; then \
		$(call script-lint,:stylesheet); \
	elif [ "$$option" == "fix" ]; then \
		$(call script-lint,:script:fix); \
	else \
		$(call script-lint,:script); \
	fi;

.PHONY: typecheck
typecheck: ## Run static type checking
	@echo "Available options:"
	@echo "- Default           : press enter"
	@echo "- Check             : check"
	@echo "- Focus check       : focus"
	@echo "- Install libdef    : install"
	@$(newline)
	@read -p "Enter the option: " option; \
	if [ "$$option" == "check" ]; then \
		$(call script-typecheck,:check); \
	elif [ "$$option" == "focus" ]; then \
		$(call script-typecheck,:check:focus); \
	elif [ "$$option" == "install" ]; then \
		$(call script-typecheck,:install); \
	else \
		$(call script-typecheck); \
	fi;

##@ Cleanup:

.PHONY: erase
erase: ## Clean up build artifacts and temporary files
	@$(call log-start,Erasing data...)
	@$(call log-step,[Step 1/2] Remove build artifacts)
	-@rm -rf -v ${DIR_BUILD} ${DIR_COVERAGE}
	@$(call log-step,[Step 2/2] Remove temporary files)
	-@rm -rf -v ${DIR_TEMP}/*
	@$(call log-success,Done)

.PHONY: refresh
refresh: ## Refresh (soft clean) the development environment
	@$(call log-start,Refreshing the development environment...)
	@$(call log-step,[Step 1/2] Stop and remove containers for the app and reverse proxy services)
	@$(call log-step,[Step 2/2] Remove the default network)
	@docker-compose down
	@$(call log-sum,[sum] Containers (including exited state))
	@docker container ls -a
	@$(call log-sum,[sum] Networks)
	@docker network ls
	@$(call log-success,Done)

.PHONY: clean
clean: ## Clean up the development environment (including persistent data)
	@$(call log-start,Cleaning up the development environment...)
	@$(call log-step,[Step 1/3] Stop and remove containers for the app and reverse proxy services)
	@$(call log-step,[Step 2/3] Remove the default network)
	@$(call log-step,[Step 3/3] Remove volumes)
	@docker-compose down -v
	@$(call log-sum,[sum] Containers (including exited state))
	@docker container ls -a
	@$(call log-sum,[sum] Networks)
	@docker network ls
	@$(call log-sum,[sum] Volumes)
	@docker volume ls
	@$(call log-success,Done)

.PHONY: reset
reset: ## Reset the development environment and clean up unused data
	@$(call log-start,Resetting the development environment...)
	@$(call log-step,[Step 1/9] Stop and remove containers for the app and reverse proxy services)
	@$(call log-step,[Step 2/9] Remove the default network)
	@$(call log-step,[Step 3/9] Remove volumes)
	-@docker-compose down -v
	@$(call log-sum,[sum] Containers (including exited state))
	@docker container ls -a
	@$(call log-sum,[sum] Networks)
	@docker network ls
	@$(call log-sum,[sum] Volumes)
	@docker volume ls
	@$(call log-step,[Step 4/9] Remove the development image)
	-@docker image rm ${IMAGE_LOCAL}/${IMAGE_REPO}
	
	@$(call log-step,[Step 5/9] Remove the production image)
	-@docker image rm ${IMAGE_NAME}
	@$(call log-step,[Step 6/9] Remove the intermediate images)
	-@docker image prune --filter label=stage=${IMAGE_LABEL_INTERMEDIATE} --force
	@$(call log-step,[Step 7/9] Remove unused images (optional))
	-@docker image prune
	@$(call log-sum,[sum] Images (including intermediates))
	@docker image ls -a
	@$(call log-step,[Step 8/9] Remove build artifacts)
	-@rm -rf -v ${DIR_BUILD} ${DIR_COVERAGE}
	@$(call log-step,[Step 9/9] Remove temporary files)
	-@rm -rf -v ${DIR_TEMP}/*
	@$(call log-success,Done)

##@ Release:

.PHONY: version
version: ## Set the next release version
	@$(call log-start,Set the next release version)
	@read -p "Enter a version number: " VERSION; \
	if [ "$$VERSION" != "" ]; then \
		echo "Your next release will be v$$VERSION"; \
		$(call set-env,RELEASE_DATE,$$(date +'%d.%m.%Y'),${CONFIG_FILE_ENV}); \
		$(call set-env,RELEASE_VERSION,$$VERSION,${CONFIG_FILE_ENV}); \
		rm ${CONFIG_FILE_ENV}.${EXT_BACKUP}; \
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
	@$(call log-step,[Step 1/3] Build an image based on the development environment)
	@$(call log-step,[Step 2/3] Create and start a container for running tests)
	@$(call log-step,[Step 3/3] Run tests and generate code coverage reports)
	@docker-compose -f ${COMPOSE_BASE} -f ${COMPOSE_CI} up ${SERVICE_APP}
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

##@ Miscellaneous:

.PHONY: info
info: ## Display system-wide information
	@$(call txt-headline,Releases)
	@echo "Date                           : ${RELEASE_DATE}"
	@echo "Version                        : ${RELEASE_VERSION}"
	@$(newline)
	@$(call txt-headline,App)
	@echo "Name                           : ${APP_NAME}"
	@echo "Repository                     : ${APP_REPO}"
	@echo "Live URL                       : ${APP_URL_LIVE}"
	@$(newline)
	@$(call txt-headline,Domain name & URLs)
	@echo "Protocal                       : ${APP_URL_PROTOCAL}"
	@echo "Top level domain (TLD)         : ${HOST_TLD}"
	@echo "Domain name                    : ${APP_DOMAIN}"
	@echo "Development URL                : ${APP_URL_LOCAL}"
	@echo "Production build URL           : ${APP_URL_BUILD}"
	@$(newline)
	@$(call txt-headline,Host machine)
	@echo "Hosts file                     : ${HOST_DNS}"
	@echo "Working directory              : $$PWD"
	@echo "Temporary path                 : ${HOST_TEMP}"
	@echo "IP address                     : ${HOST_IP}"
	@$(newline)
	@$(call txt-headline,Base images)
	@echo "NGINX                          : ${IMAGE_BASE_NGINX}"
	@echo "Node.js                        : ${IMAGE_BASE_NODE}"
	@echo "Proxy                          : ${IMAGE_BASE_PROXY}"
	@$(newline)
	@$(call txt-headline,Image & Container)
	@echo "Cloud-based registry service   : ${IMAGE_REGISTRY}"
	@echo "Username                       : ${IMAGE_USERNAME}"
	@echo "Repository                     : ${IMAGE_REPO}"
	@echo "Tag                            : ${RELEASE_VERSION}"
	@echo "Name                           : ${IMAGE_NAME}"
	@echo "Description                    : ${IMAGE_DESCRIPTION}"
	@echo "Intermediate image             : ${IMAGE_LABEL_INTERMEDIATE}"
	@echo "Temporary path                 : ${CONTAINER_TEMP}"
	@echo "Working directory              : ${CONTAINER_WORKDIR}"
	@$(newline)
	@$(call txt-headline,Configuration files)
	@echo "Amazon Web Services (AWS)      : ${CONFIG_AWS}"
	@echo "NPM & Yarn                     : ${CONFIG_FILE_NPM}"
	@echo "Travis CI                      : ${CONFIG_CI}"
	@echo "Environment variables          : ${CONFIG_FILE_ENV}"
	@$(newline)
	@$(call txt-headline,Files & Directories)
	@echo "Optimized production build     : ${DIR_BUILD}"
	@echo "Code coverage                  : ${DIR_COVERAGE}"
	@echo "Temporary                      : ${DIR_TEMP}"
	@echo "Treemap                        : ${FILE_TREEMAP}"
	@$(newline)
	@$(call txt-headline,Ports)
	@echo "Development server             : ${PORT_EXPOSE_APP}"
	@echo "Reverse proxy server           : ${PORT_EXPOSE_PROXY}"
	@echo "Unsecured HTTP port mapping    : ${PORT_MAPPING_DEFAULT}"
	@echo "SSL port mapping               : ${PORT_MAPPING_SSL}"
	@$(newline)
	@$(call txt-headline,Miscellaneous)
	@echo "Default browser                : ${BROWSER_DEFAULT}"
	@echo "License                        : ${LICENSE}"
	@$(newline)
	@$(call txt-headline,Maintainer)
	@echo "Name                           : ${AUTHOR_NAME}"
	@echo "Email                          : ${AUTHOR_EMAIL}"
	@$(newline)

.PHONY: setup
setup: ## Setup the development environment and install dependencies
	@$(call log-start,Setting up the development environment...)
	@$(call log-step,[Step 1/2] Install dependencies required for running on the development environment)
	@docker pull ${IMAGE_BASE_NGINX}
	@docker pull ${IMAGE_BASE_NODE}
	@docker pull ${IMAGE_BASE_PROXY}
	@$(call log-step,[Step 2/2] Set a custom domain for a self-signed SSL certificate)
	@$(call script-host,${APP_DOMAIN_LOCAL})
	@$(call script-host,${APP_DOMAIN_BUILD})
	@$(call log-success,Done)

.PHONY: help
help: ## Print usage
	@awk 'BEGIN {FS = ":.*##"; \
	printf "\nUsage: make \033[${ANSI_COLOR_CYAN}m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ \
	{ printf "  \033[${ANSI_COLOR_CYAN}m%-27s\033[0m %s\n", $$1, $$2 } /^##@/ \
	{ printf "\n\033[0m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
