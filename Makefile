# Dependencies
include .env

# Variables
SHELL := /bin/bash
, := ,
blank :=
space := $(blank) $(blank)

# Date and time
CURRENT_DATE = $$(date +'%d.%m.%Y')

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

# Text and string
txt-template = printf "\e[100m make \e[${1};49m $(2)\e[0m \n"
txt-danger = $(call txt-template,${ANSI_COLOR_RED},$(1));
txt-info = $(call txt-template,${ANSI_COLOR_WHITE},$(1));
txt-start = $(call txt-template,${ANSI_COLOR_MAGENTA},$(1));
txt-step = $(call txt-template,${ANSI_COLOR_YELLOW},$(1));
txt-success = $(call txt-template,${ANSI_COLOR_GREEN},$(1));
txt-sum = $(call txt-template,${ANSI_COLOR_CYAN},$(1));
txt-bold = \e[1m$(1)\e[0m
txt-italic = \e[3m$(1)\e[0m
txt-underline = \e[4m$(1)\e[0m
txt-headline = printf "\e[${ANSI_COLOR_CYAN};49;1m$(1)\e[0m \n\n"
txt-done = $(call txt-success,Done)
txt-skipped = echo "Skipped"
txt-confirm = echo "Skipped, please enter y/yes or n/no"
txt-note = $(call txt-underline,Note)
txt-warning = $(call txt-underline,Warning)
newline = echo ""

# Set configuration values
set-json = sed -i.${EXT_BACKUP} 's|\(.*"$(1)"\): "\(.*\)"$(3).*|\1: '"\"$(2)\"$(3)|" $(4)
set-env = sed -i.${EXT_BACKUP} 's;^$(1)=.*;$(1)='"$(2)"';' $(3)

# Host names
function-host = echo "${HOST_IP}       $(1)" | sudo tee -a ${HOST_DNS}

# Preview
define function-preview
	$(call txt-info,Opening $(1) in the default browser...) \
	$(txt-done) \
	open -a ${BROWSER_DEFAULT} $(1)
endef

# Test
define function-test
	$(call txt-step,[Step 1/4] Build the development image (if needed)) \
	$(call txt-step,[Step 2/4] Create and start a container for running tests) \
	$(call txt-step,[Step 3/4] Run tests) \
	$(call txt-step,[Step 4/4] Remove the container when the process finishes) \
	docker-compose \
	-f ${COMPOSE_BASE} \
	-f ${COMPOSE_DEVELOPMENT} \
	-f ${COMPOSE_TEST} run \
	--name ${IMAGE_REPO}-${SUFFIX_TEST} \
	--rm \
	${SERVICE_APP} test$(1)
endef

# Linting
define function-lint
	$(call txt-step,[Step 1/4] Build the development image (if needed)) \
	$(call txt-step,[Step 2/4] Create and start a container for running code linting) \
	$(call txt-step,[Step 3/4] Run linting) \
	$(call txt-step,[Step 4/4] Remove the container when the process finishes) \
	docker-compose run --rm ${SERVICE_APP} lint$(1)
endef

# Static type checking
define function-typecheck
	$(call txt-step,[Step 1/4] Build the development image (if needed)) \
	$(call txt-step,[Step 2/4] Create and start a container for running static type checking) \
	$(call txt-step,[Step 3/4] Run static type checking) \
	$(call txt-step,[Step 4/4] Remove the container when the process finishes) \
	docker-compose run --rm ${SERVICE_APP} type$(1)
endef

# Release
define function-release
	$(call txt-step,[Step 1/2] Configure ${CONFIG_AWS} for AWS Elastic Beanstalk deployment)
	$(call set-json,Name,${IMAGE_NAME},$(,),${CONFIG_AWS})
	$(call set-json,ContainerPort,${PORT_EXPOSE_PROXY},$(blank),${CONFIG_AWS})
	$(call txt-step,[Step 2/2] Configure ${CONFIG_NPM} for AWS Node.js deployment)
	$(call set-json,version,${RELEASE_VERSION},$(,),${CONFIG_NPM})
	
	# Remove backup files after performing text transformations
	rm *.${EXT_BACKUP}
endef

##@ Development:

.PHONY: start
start: ## Start the development environment and attach to containers for a service
	@$(call txt-start,Starting the development environment...)
	@$(call txt-step,[Step 1/4] Download base images (if needed))
	@$(call txt-step,[Step 2/4] Build the development image (if needed))
	@$(call txt-step,[Step 3/4] Create and start the development and reverse proxy containers)
	@$(call txt-step,[Step 4/4] Start the development and reverse proxy servers)
	@$(call txt-info,You can view ${APP_NAME} in the browser at ${APP_URL_LOCAL})
	@docker-compose up

.PHONY: restart
restart: ## Rebuild and restart the development environment
	@$(call txt-start,Restarting the development environment...)
	@$(call txt-step,[Step 1/3] Rebuild the development image)
	@$(call txt-step,[Step 2/3] Create and start the development and reverse proxy containers)
	@$(call txt-step,[Step 3/3] Start the development and reverse proxy servers)
	@$(call txt-info,You can view ${APP_NAME} in the browser at ${APP_URL_LOCAL})
	@docker-compose up --build

.PHONY: stop
stop: ## Stop running containers without removing them
	@$(call txt-start,Stopping running containers...)
	@docker-compose stop
	@$(txt-done)

.PHONY: up
up: ## Rebuild image for the development environment
	@$(call txt-start,This command will perform the following actions:)
	@echo "- Stop running containers without removing them"
	@echo "- Rebuild image for the development environment"
	@$(newline)
	@read -p "Stop working on the app and rebuild the image? " confirmation; \
	case "$$confirmation" in \
		[yY] | [yY][eE][sS]) \
			$(call txt-start,Rebuilding image for the the development environment...) \
			$(call txt-step,[Step 1/3] Stop running containers) \
			docker-compose stop; \
			$(call txt-step,[Step 2/3] Download base images (if needed)) \
			$(call txt-step,[Step 3/3] Rebuild the image) \
			docker-compose build; \
			$(txt-done) \
		;; \
		[nN] | [nN][oO]) \
			$(txt-skipped) \
		;; \
		*) \
			$(txt-confirm); \
		;; \
	esac

.PHONY: build
build: ## Create an optimized production build
	@$(call txt-start,Creating an optimized production build...)
	@$(call txt-step,[Step 1/6] Remove the existing build (if one exists))
	-@rm -rf -v ${DIR_BUILD}
	@$(call txt-step,[Step 2/6] Download base images (if needed))
	@$(call txt-step,[Step 3/6] Build the development image (if it doesn't exist))
	@$(call txt-step,[Step 4/6] Create and start a container for building the app)
	@$(call txt-step,[Step 5/6] Create an optimized production build)
	@$(call txt-step,[Step 6/6] Stop and remove the container)
	@docker-compose run --rm ${SERVICE_APP} build
	@$(call txt-info,The production build has been created successfully in $(call txt-bold,./${DIR_BUILD}) directory)
	@ls ${DIR_BUILD}
	@$(txt-done)

.PHONY: preview
preview: ## Preview the production build locally
	@$(call txt-start,Running the production build...)
	@$(call txt-step,[Step 1/6] Remove intermediate and unused images (when necessary))
	-@docker image prune --filter label=stage=${IMAGE_LABEL_INTERMEDIATE} --force
	@$(call txt-step,[Step 2/6] Download base images (if needed))
	@$(call txt-step,[Step 3/6] Create an optimized production build)
	@$(call txt-step,[Step 4/6] Build the production image tagged $(call txt-bold,${IMAGE_NAME}))
	@$(call txt-step,[Step 5/6] Create and start the app and reverse proxy containers)
	@$(call txt-step,[Step 6/6] Start the web (for serving the app) and reverse proxy servers)
	@$(call txt-info,You can view $(call txt-bold,${APP_NAME}) in the browser at ${APP_URL_BUILD})
	@docker-compose \
	-f ${COMPOSE_BASE} \
	-f ${COMPOSE_PRODUCTION} \
	up --build

##@ Utilities:

.PHONY: open
open: ## Open the app in the default browser *
	@echo "Available options:"
	@echo "- Development            : press enter"
	@echo "- Local production build : build"
	@echo "- Staging                : unavailable"
	@echo "- Live / Production      : live"
	@$(newline)
	@read -p "Enter the option: " option; \
	if [ "$$option" == "build" ]; then \
		$(call function-preview,${APP_URL_BUILD}); \
	elif [ "$$option" == "live" ]; then \
		$(call function-preview,${APP_URL_LIVE}); \
	else \
		$(call function-preview,${APP_URL_LOCAL}); \
	fi;

.PHONY: shell
shell: ## Attach an interactive shell to the development container
	@$(call txt-start,Attaching an interactive shell to the development container...)
	@docker container exec -it ${IMAGE_REPO}-${SUFFIX_LOCAL} sh

.PHONY: format
format: ## Format code automatically
	@$(call txt-start,Formatting code...)
	@$(call txt-step,[Step 1/4] Build the development image (if needed))
	@$(call txt-step,[Step 2/4] Create and start a container for formatting code)
	@$(call txt-step,[Step 3/4] Format code)
	@$(call txt-step,[Step 4/4] Remove the container)
	@docker-compose run --rm ${SERVICE_APP} format
	@$(txt-done)

.PHONY: analyze
analyze: CONTAINER_NAME = ${IMAGE_REPO}-analyzing
analyze: build ## Analyze and debug code bloat through source maps
	@$(call txt-start,Analyzing and debugging code...)
	@$(call txt-step,[Step 1/5] Create and start a container for analyzing the bundle)
	@$(call txt-step,[Step 2/5] Analyze the bundle size)
	@docker-compose run --name ${CONTAINER_NAME} ${SERVICE_APP} analyze
	@$(call txt-step,[Step 3/5] Copy the result from the container's file system to the host's)
	@docker cp ${CONTAINER_NAME}:${CONTAINER_TEMP}/. ${HOST_TEMP}
	@$(call txt-step,[Step 4/5] Remove the container)
	@docker container rm ${CONTAINER_NAME}
	@$(call txt-step,[Step 5/5] Open the treemap visualization in the browser)
	@$(call function-preview,${HOST_TEMP}/${FILE_TREEMAP})

.PHONY: setup
setup: ## Setup the development environment and install dependencies
	@$(call txt-start,Setting up the development environment...)
	@$(call txt-step,[Step 1/2] Install dependencies required for running on the development environment)
	@docker pull ${IMAGE_BASE_NGINX}
	@docker pull ${IMAGE_BASE_NODE}
	@docker pull ${IMAGE_BASE_PROXY}
	@$(call txt-step,[Step 2/2] Set a custom domain for a self-signed SSL certificate)
	@$(call function-host,${APP_DOMAIN_LOCAL})
	@$(call function-host,${APP_DOMAIN_BUILD})
	@$(txt-done)

##@ Testing & Linting:

.PHONY: test
test: ## Run tests *
	@echo "Available modes:"
	@echo "- Watch mode    : press enter"
	@echo "- Code coverage : coverage"
	@echo "- Silent        : sum"
	@echo "- Details       : details"
	@$(newline)
	@read -p "Enter test mode: " mode; \
	if [ "$$mode" == "coverage" ]; then \
		$(call function-test,:coverage); \
		$(call txt-sum,[sum] LCOV data is created in ${DIR_ROOT}${DIR_COVERAGE} directory) \
		ls ${DIR_COVERAGE}; \
	else \
		$(call function-test); \
	fi;

.PHONY: lint
lint: ## Run code linting *
	@echo "Available options:"
	@echo "- JavaScript        : press enter"
	@echo "- JavaScript (fix)  : fix"
	@echo "- Stylesheet        : stylesheet"
	@$(newline)
	@read -p "Enter the option: " option; \
	if [ "$$option" == "stylesheet" ]; then \
		$(call function-lint,:stylesheet); \
	elif [ "$$option" == "fix" ]; then \
		$(call function-lint,:script:fix); \
	else \
		$(call function-lint,:script); \
	fi;

.PHONY: typecheck
typecheck: ## Run static type checking *
	@echo "Available options:"
	@echo "- Default           : press enter"
	@echo "- Check             : check"
	@echo "- Focus check       : focus"
	@echo "- Install libdef    : install"
	@$(newline)
	@read -p "Enter the option: " option; \
	if [ "$$option" == "check" ]; then \
		$(call function-typecheck,:check); \
	elif [ "$$option" == "focus" ]; then \
		$(call function-typecheck,:check:focus); \
	elif [ "$$option" == "install" ]; then \
		$(call function-typecheck,:install); \
		$(call txt-info,The library definitions (libdef) have been updated$(,) please commit the changes in $(call txt-bold,./${DIR_BUILD}) directory) \
		$(txt-done) \
	else \
		$(call function-typecheck); \
	fi;

##@ Packages & Dependencies:

.PHONY: install
install: ## Install a package and any packages that it depends on **
	@read -p "Enter package name: " package; \
	if [ "$$package" != "" ]; then \
		$(call txt-start,Installing npm package...) \
		$(call txt-step,[Step 1/5] Build the development image (if needed)) \
		$(call txt-step,[Step 2/5] Create and start a container for installing dependencies) \
		$(call txt-step,[Step 3/5] Install $$package package in the persistent storage (volume)) \
		$(call txt-step,[Step 4/5] Update package.json and yarn.lock) \
		$(call txt-step,[Step 5/5] Remove the container) \
		docker-compose run --rm ${SERVICE_APP} add $$package; \
		$(txt-done) \
	else \
		echo "Skipped, you did not enter the package name, please try again"; \
	fi;

.PHONY: uninstall
uninstall: ## Uninstall a package **
	@read -p "Enter package name: " package; \
	if [ "$$package" != "" ]; then \
		$(call txt-start,Uninstalling npm package...) \
		$(call txt-step,[Step 1/5] Build the development image (if needed)) \
		$(call txt-step,[Step 2/5] Create and start a container for uninstalling dependencies) \
		$(call txt-step,[Step 3/5] Uninstall $$package package from the persistent storage (volume)) \
		$(call txt-step,[Step 4/5] Update package.json and yarn.lock) \
		$(call txt-step,[Step 5/5] Remove the container) \
		docker-compose run --rm ${SERVICE_APP} remove $$package; \
		$(txt-done) \
	else \
		echo "Skipped, you did not enter the package name, please try again"; \
	fi;

.PHONY: update
update: ## Install and update all the dependencies listed within package.json
	@$(call txt-start,Updating dependencies...)
	@$(call txt-step,[Step 1/5] Build the development image (if needed))
	@$(call txt-step,[Step 2/5] Create and start a container for formatting code)
	@$(call txt-step,[Step 3/5] Install and update dependencies in the persistent storage (volume))
	@$(call txt-step,[Step 4/5] Update yarn.lock (if necessary))
	@$(call txt-step,[Step 5/5] Remove the container)
	@docker-compose run --rm ${SERVICE_APP} install
	@$(txt-done)

##@ Cleanup:

.PHONY: erase
erase: ## Clean up build artifacts and temporary files
	@$(call txt-start,This command will perform the following actions:)
	@echo "- Remove all build artifacts"
	@echo "- Remove all temporary files"
	@$(newline)
	@printf "$(txt-note): You are about to permanently remove files and folders. You will not be able to recover these folders or their contents. $(call txt-bold,This operation cannot be undone.)\n"
	@$(newline)
	@read -p "Remove build artifacts and temporary files? " confirmation; \
	case "$$confirmation" in \
		[yY] | [yY][eE][sS]) \
			$(call txt-start,Removing data...) \
			$(call txt-step,[Step 1/2] Remove build artifacts) \
			rm -rf -v ${DIR_BUILD} ${DIR_COVERAGE}; \
			$(call txt-step,[Step 2/2] Remove temporary files) \
			rm -rf -v ${DIR_TEMP}/*; \
			$(txt-done) \
		;; \
		[nN] | [nN][oO]) \
			$(txt-skipped) \
		;; \
		*) \
			$(txt-confirm); \
		;; \
	esac

.PHONY: refresh
refresh: ## Refresh (soft clean) the development environment
	@$(call txt-start,This command will perform the following actions:)
	@echo "- Stop and remove containers for the app and reverse proxy services"
	@echo "- Remove the default network"
	@$(newline)
	@read -p "Refresh the development environment? " confirmation; \
	case "$$confirmation" in \
		[yY] | [yY][eE][sS]) \
			$(call txt-start,Refreshing the development environment...) \
			$(call txt-step,[Step 1/2] Stop and remove containers for the app and reverse proxy services) \
			$(call txt-step,[Step 2/2] Remove the default network) \
			docker-compose down; \
			$(call txt-sum,[sum] Containers (including exited state)) \
			docker container ls -a; \
			$(call txt-sum,[sum] Networks) \
			docker network ls; \
			$(txt-done) \
		;; \
		[nN] | [nN][oO]) \
			$(txt-skipped) \
		;; \
		*) \
			$(txt-confirm); \
		;; \
	esac

.PHONY: clean
clean: ## Clean up the development environment (including persistent data)
	@$(call txt-start,This command will perform the following actions:)
	@echo "- Stop and remove containers for the app and reverse proxy  \services"
	@echo "- Remove the default network"
	@echo "- Remove volumes"
	@$(newline)
	@printf "$(txt-note): You are about to permanently remove persistent data. $(call txt-bold,This operation cannot be undone.)\n"
	@$(newline)
	@read -p "Clean up the development environment? " confirmation; \
	case "$$confirmation" in \
		[yY] | [yY][eE][sS]) \
			$(call txt-start,Cleaning up the development environment...) \
			$(call txt-step,[Step 1/3] Stop and remove containers for the app and reverse proxy services) \
			$(call txt-step,[Step 2/3] Remove the default network) \
			$(call txt-step,[Step 3/3] Remove volumes) \
			docker-compose down -v; \
			$(call txt-sum,[sum] Containers (including exited state)) \
			docker container ls -a; \
			$(call txt-sum,[sum] Networks) \
			docker network ls; \
			$(call txt-sum,[sum] Volumes) \
			docker volume ls; \
			$(txt-done) \
		;; \
		[nN] | [nN][oO]) \
			$(txt-skipped) \
		;; \
		*) \
			$(txt-confirm); \
		;; \
	esac

.PHONY: reset
reset: ## Reset the development environment and clean up unused data
	@$(call txt-start,This command will perform the following actions:)
	@echo "- Stop and remove containers for the app and reverse proxy services"
	@echo "- Remove the default network"
	@echo "- Remove volumes"
	@echo "- Remove the development image"
	@echo "- Remove the production image"
	@echo "- Remove the intermediate images"
	@echo "- Remove unused images (optional)"
	@echo "- Remove build artifacts"
	@echo "- Remove temporary files"
	@$(newline)
	@printf "$(txt-note): You are about to permanently remove files and folders. You will not be able to recover these folders or their contents. $(call txt-bold,This operation cannot be undone.)\n"
	@$(newline)
	@read -p "Reset the development environment and clean up unused data? " confirmation; \
	case "$$confirmation" in \
		[yY] | [yY][eE][sS]) \
			$(call txt-start,Resetting the development environment...) \
			$(call txt-step,[Step 1/9] Stop and remove containers for the app and reverse proxy services) \
			$(call txt-step,[Step 2/9] Remove the default network) \
			$(call txt-step,[Step 3/9] Remove volumes) \
			docker-compose down -v; \
			$(newline); \
			$(call txt-sum,List containers (including exited state)) \
			docker container ls -a; \
			$(newline); \
			$(call txt-sum,List networks) \
			docker network ls; \
			$(newline); \
			$(call txt-sum,List volumes) \
			docker volume ls; \
			$(newline); \
			$(call txt-step,[Step 4/9] Remove the development image) \
			docker image rm ${ENV_LOCAL}/${IMAGE_REPO}; \
			$(call txt-step,[Step 5/9] Remove the production image) \
			docker image rm ${IMAGE_NAME}; \
			$(call txt-step,[Step 6/9] Remove the intermediate images) \
			docker image prune --filter label=stage=${IMAGE_LABEL_INTERMEDIATE} --force; \
			$(call txt-step,[Step 7/9] Remove unused images (optional)) \
			docker image prune; \
			$(newline); \
			$(call txt-sum,List images (including intermediates)) \
			docker image ls -a; \
			$(newline); \
			$(call txt-step,[Step 8/9] Remove build artifacts) \
			rm -rf -v ${DIR_BUILD} ${DIR_COVERAGE}; \
			$(newline); \
			$(call txt-step,[Step 9/9] Remove temporary files) \
			rm -rf -v ${DIR_TEMP}/*; \
			$(txt-done) \
		;; \
		[nN] | [nN][oO]) \
			$(txt-skipped) \
		;; \
		*) \
			$(txt-confirm); \
		;; \
	esac

##@ Operations:

.PHONY: version
version: ## Set the next release version **
	@$(call txt-start,Setting the next release version...)
	@printf "The current version is $(call txt-bold,v${RELEASE_VERSION}) (released on ${RELEASE_DATE})\n"
	@$(newline)
	@printf "$(txt-warning): You $(call txt-bold,must) reset the development environment built with the configuration from v${RELEASE_VERSION} before tagging a new release version, otherwise you will not be able to remove the outdate environment once you have tagged a new version. To do that, cancel this command by hitting $(call txt-bold,enter/return) key and run $(call txt-bold,reset) command\n"
	@$(newline)
	@read -p "Enter a version number: " VERSION; \
	if [ "$$VERSION" != "" ]; then \
		printf "The next release will be $(call txt-bold,v$$VERSION) on ${CURRENT_DATE} (today)\n"; \
		$(call set-env,RELEASE_DATE,${CURRENT_DATE},${CONFIG_ENV}); \
		$(call set-env,RELEASE_VERSION,$$VERSION,${CONFIG_ENV}); \
		rm ${CONFIG_ENV}.${EXT_BACKUP}; \
		$(txt-done) \
	else \
		$(txt-skipped); \
	fi;

.PHONY: release
release: ## Release new features
	@$(call txt-start,Release new features)
	@$(function-release)
	@$(txt-done)

##@ Continuous Integration:

.PHONY: ci-update
ci-update: ## Install additional dependencies required for running on the CI environment
	@$(call txt-start,Installing additional dependencies...)
	@$(call txt-step,[Step 1/1] Update Docker Compose to version ${DOCKER_COMPOSE_VERSION})
	@sudo rm ${BINARY_PATH}/docker-compose
	@curl -L ${DOCKER_COMPOSE_REPO}/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > docker-compose
	@chmod +x docker-compose
	@sudo mv docker-compose ${BINARY_PATH}
	@$(txt-done)

.PHONY: ci-setup
ci-setup: ## Setup the CI environment and install required dependencies
	@$(call txt-start,Setting up the CI environment...)
	@$(call txt-step,[Step 1/2] Install dependencies required for running on the CI environment)
	@docker pull ${IMAGE_BASE_NGINX}
	@docker pull ${IMAGE_BASE_NODE}
	@$(call txt-step,[Step 2/2] List downloaded Docker images)
	@docker image ls
	@$(txt-done)

.PHONY: ci-test
ci-test: ## Run tests and generate code coverage reports
	@$(call txt-start,Running tests...)
	@$(call txt-step,[Step 1/3] Build an image based on the development environment)
	@$(call txt-step,[Step 2/3] Create and start a container for running tests)
	@$(call txt-step,[Step 3/3] Run tests and generate code coverage reports)
	@docker-compose -f ${COMPOSE_BASE} -f ${COMPOSE_CI} up ${SERVICE_APP}
	@$(txt-done)

.PHONY: ci-coverage
ci-coverage: ## Create code coverage reports (LCOV format)
	@$(call txt-start,Creating code coverage reports...)
	@$(call txt-step,[Step 1/2] Copy LCOV data from the container\'s file system to the CI\'s)
	@docker cp ${CONTAINER_NAME_CI}:${CONTAINER_WORKDIR}/${DIR_COVERAGE} ${DIR_ROOT}
	@$(call txt-step,[Step 2/2] Fix source paths in the LCOV file)
	@yarn replace ${CONTAINER_WORKDIR} ${TRAVIS_BUILD_DIR} ${LCOV_DATA} --silent
	@$(txt-done)

.PHONY: ci-deploy
ci-deploy: ## Create deployment configuration and build a production image
	@$(call txt-start,Configuring a deployment configuration...)
	@$(function-release)
	@$(call txt-start,Building a deployment configuration...)
	@$(call txt-step,[Step 1/1] Build ${BUILD_ZIP} for uploading to AWS S3 service)
	@zip ${BUILD_ZIP} ${CONFIG_AWS}
	@$(call txt-start,Building a production image (version ${RELEASE_VERSION}) for deployment...)
	@$(call txt-step,[Step 1/3] Build the image)
	@docker-compose -f ${COMPOSE_BASE} -f ${COMPOSE_PRODUCTION} build ${SERVICE_APP}
	@$(call txt-step,[Step 2/3] Login to Docker Hub)
	@echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
	@$(call txt-step,[Step 3/3] Push the image to Docker Hub)
	@docker push ${IMAGE_NAME}
	@$(txt-done)

.PHONY: ci-coveralls
ci-coveralls: ## Send LCOV data (code coverage reports) to coveralls.io
	@$(call txt-start,Sending LCOV data to coveralls.io...)
	@$(call txt-step,[Step 1/2] Collect LCOV data from /coverage/lcov.info)
	@$(call txt-step,[Step 2/2] Send the data to coveralls.io)
	@cat ${LCOV_DATA} | coveralls
	@$(txt-done)

.PHONY: ci-clean
ci-clean: ## Remove unused data from the CI server
	@$(call txt-start,Removing unused data...)
	@docker system prune --all --volumes --force
	@$(txt-done)

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
	@echo "NPM & Yarn                     : ${CONFIG_NPM}"
	@echo "Travis CI                      : ${CONFIG_CI}"
	@echo "Environment variables          : ${CONFIG_ENV}"
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
	@echo "License                        : ${IMAGE_LICENSE}"
	@$(newline)
	@$(call txt-headline,Maintainer)
	@echo "Name                           : ${AUTHOR_NAME}"
	@echo "Email                          : ${AUTHOR_EMAIL}"
	@$(newline)

.PHONY: status
status: ## Show system status
	@$(call txt-sum,List images (including intermediates))
	@docker image ls -a
	@$(newline)
	@$(call txt-sum,List containers (including exited state))
	@docker container ls -a
	@$(newline)
	@$(call txt-sum,List networks)
	@docker network ls
	@$(newline)
	@$(call txt-sum,List volumes)
	@docker volume ls
	@$(newline)
	@$(call txt-sum,Show the working tree status)
	@git status

.PHONY: help
help: ## Print usage
	@awk 'BEGIN {FS = ":.*##"; \
	printf "\nUsage: make \033[${ANSI_COLOR_CYAN}m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ \
	{ printf "  \033[${ANSI_COLOR_CYAN}m%-27s\033[0m %s\n", $$1, $$2 } /^##@/ \
	{ printf "\n\033[0m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@$(newline)
	@printf "*  with options\n"
	@printf "** requires user input\n\n"
