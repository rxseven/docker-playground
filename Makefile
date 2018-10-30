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

# Loggers
log-template = printf "\e[100m make \e[${1};49m $(2)\e[0m \n"
log-danger = $(call log-template,${ANSI_COLOR_RED},$(1));
log-info = $(call log-template,${ANSI_COLOR_WHITE},$(1));
log-start = $(call log-template,${ANSI_COLOR_MAGENTA},$(1));
log-step = $(call log-template,${ANSI_COLOR_YELLOW},$(1));
log-success = $(call log-template,${ANSI_COLOR_GREEN},$(1));
log-sum = $(call log-template,${ANSI_COLOR_CYAN},$(1));
log-bold = \e[1m$(1)\e[0m
log-italic = \e[3m$(1)\e[0m
log-underline = \e[4m$(1)\e[0m

# Text and string
txt-confirm = echo "Skipped, please enter y/yes or n/no"
txt-done = $(call log-success,Done)
txt-headline = printf "\e[${ANSI_COLOR_CYAN};49;1m$(1)\e[0m \n\n"
txt-note = $(call log-underline,Note)
txt-opps = echo "Opps! please try again."
txt-options = printf "* default option, press $(call log-bold,enter) key to continue / enter $(call log-bold,0) to cancel.\n"
txt-skipped = echo "Skipped"
txt-warning = $(call log-underline,Warning)
newline = echo ""

# Set configuration values
set-json = sed -i.${EXT_BACKUP} 's|\(.*"$(1)"\): "\(.*\)"$(3).*|\1: '"\"$(2)\"$(3)|" $(4)
set-env = sed -i.${EXT_BACKUP} 's;^$(1)=.*;$(1)='"$(2)"';' $(3)

# Host names
function-host = echo "${HOST_IP}       $(1)" | sudo tee -a ${HOST_DNS}

# View app in the browser
define function-browser
	$(call log-info,Opening $(1) in the default browser...) \
	$(txt-done) \
	open -a ${BROWSER_DEFAULT} $(1)
endef

# Preview the production build
define function-preview
	$(call log-start,Running the production build...) \
	$(call log-step,[Step 1/5] Download base images (if needed)) \
	$(call log-step,[Step 2/5] Create an optimized production build) \
	$(call log-step,[Step 3/5] Build the production image tagged $(call log-bold,${IMAGE_NAME})) \
	$(call log-step,[Step 4/5] Create and start the app and reverse proxy containers) \
	$(call log-step,[Step 5/5] Start the web (for serving the app) and reverse proxy servers) \
	$(call log-info,You can view $(call log-bold,${APP_NAME}) in the browser at ${APP_URL_BUILD}) \
	docker-compose -f ${COMPOSE_BASE} -f ${COMPOSE_PRODUCTION} up $(1)
endef

# Test
define function-test
	$(call log-step,[Step 1/4] Build the development image (if needed)) \
	$(call log-step,[Step 2/4] Create and start a container for running tests) \
	$(call log-step,[Step 3/4] Run tests) \
	$(call log-step,[Step 4/4] Remove the container when the process finishes) \
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
	$(call log-step,[Step 1/4] Build the development image (if needed)) \
	$(call log-step,[Step 2/4] Create and start a container for running code linting) \
	$(call log-step,[Step 3/4] Run linting) \
	$(call log-step,[Step 4/4] Remove the container when the process finishes) \
	docker-compose run --rm ${SERVICE_APP} lint$(1)
endef

# Static type checking
define function-typecheck
	$(call log-step,[Step 1/4] Build the development image (if needed)) \
	$(call log-step,[Step 2/4] Create and start a container for running static type checking) \
	$(call log-step,[Step 3/4] Run static type checking) \
	$(call log-step,[Step 4/4] Remove the container when the process finishes) \
	docker-compose run --rm ${SERVICE_APP} type$(1)
endef

# Release
define function-release
	$(call log-step,[Step 1/2] Configure ${CONFIG_AWS} for AWS Elastic Beanstalk deployment)
	$(call set-json,Name,${IMAGE_NAME},$(,),${CONFIG_AWS})
	$(call set-json,ContainerPort,${PORT_EXPOSE_PROXY},$(blank),${CONFIG_AWS})
	$(call log-step,[Step 2/2] Configure ${CONFIG_NPM} for AWS Node.js deployment)
	$(call set-json,version,${RELEASE_VERSION},$(,),${CONFIG_NPM})
	
	# Remove backup files after performing text transformations
	rm *.${EXT_BACKUP}
endef

# Install and update dependencies
define function-update
	$(call log-start,Updating dependencies...)
	$(call log-step,[Step 1/5] Build the development image (if needed))
	$(call log-step,[Step 2/5] Create and start a container for updating dependencies)
	$(call log-step,[Step 3/5] Install and update dependencies in the persistent storage (volume))
	$(call log-step,[Step 4/5] Update yarn.lock (if necessary))
	$(call log-step,[Step 5/5] Remove the container)
	docker-compose run --rm ${SERVICE_APP} install
endef

# Start the development environment
define function-start
	$(call log-start,Starting the development environment...)
	$(call log-step,[Step 1/4] Download base images (if needed))
	$(call log-step,[Step 2/4] Build the development image (if needed))
	$(call log-step,[Step 3/4] Create and start the development and reverse proxy containers)
	$(call log-step,[Step 4/4] Start the development and reverse proxy servers)
	$(call log-info,You can view ${APP_NAME} in the browser at ${APP_URL_LOCAL})
	docker-compose up
endef

# Remove build artifacts
define function-artifacts
	if [[ -d "${DIR_BUILD}" || -d "${DIR_COVERAGE}" ]]; then \
		rm -rf -v ${DIR_BUILD} ${DIR_COVERAGE}; \
	else \
		echo "Skipped, no build artifacts found."; \
	fi;
endef

# Remove temporary files
define function-temporary
	for f in ${DIR_TEMP}/*; do \
		[ -e "$$f" ] && \
		rm -rf -v ${DIR_TEMP}/* || \
		echo "Skipped, no temporary files found."; \
		break; \
	done;
endef

# Docker summary
define sum-docker
	$(call log-sum,Containers (including exited state)) \
	docker container ls -a; \
	$(newline); \
	$(call log-sum,Networks) \
	docker network ls; \
	$(newline); \
	$(call log-sum,Volumes) \
	docker volume ls; \
	$(newline); \
	$(call log-sum,Images (including intermediates)) \
	docker image ls -a;
endef

# Build artifacts summary
define sum-artifacts
	$(call log-sum,Build artifacts) \
	if [[ -d "${DIR_BUILD}" || -d "${DIR_COVERAGE}" ]]; then \
		echo "Opps! there are some artifacts left, please try again."; \
	else \
		echo "All clean"; \
	fi;
endef

# Temporary files summary
define sum-temporary
	$(call log-sum,Temporary files) \
	for f in ${DIR_TEMP}/*; do \
		[ -e "$$f" ] && \
		echo "Opps! there are some files left, please try again." || \
		echo "All clean"; \
		break; \
	done;
endef

##@ Development:

.PHONY: start
start: ## Start the development environment and attach to containers for a service
	@$(function-start)

.PHONY: restart
restart: ## Rebuild and restart the development environment
	@$(call log-start,Restarting the development environment...)
	@$(call log-step,[Step 1/3] Rebuild the development image)
	@$(call log-step,[Step 2/3] Create and start the development and reverse proxy containers)
	@$(call log-step,[Step 3/3] Start the development and reverse proxy servers)
	@$(call log-info,You can view ${APP_NAME} in the browser at ${APP_URL_LOCAL})
	@docker-compose up --build

.PHONY: stop
stop: ## Stop running containers without removing them
	@$(call log-start,Stopping running containers...)
	@docker-compose stop
	@$(txt-done)

.PHONY: run
run: ## Update dependencies and start the development environment
	@$(function-update)
	@$(function-start)

.PHONY: up
up: ## Rebuild images for the development environment
	@$(call log-start,This command will perform the following actions:)
	@echo "- Stop running containers without removing them"
	@echo "- Rebuild images for the development environment"
	@$(newline)
	@read -p "Stop working on the app and rebuild the images? " confirmation; \
	case "$$confirmation" in \
		[yY] | [yY][eE][sS]) \
			$(call log-start,Rebuilding images for the the development environment...) \
			$(call log-step,[Step 1/3] Stop running containers) \
			docker-compose stop; \
			$(call log-step,[Step 2/3] Download base images (if needed)) \
			$(call log-step,[Step 3/3] Rebuild the images) \
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
	@$(call log-start,Creating an optimized production build...)
	@$(call log-step,[Step 1/6] Remove the existing build (if one exists))
	-@rm -rf -v ${DIR_BUILD}
	@$(call log-step,[Step 2/6] Download base images (if needed))
	@$(call log-step,[Step 3/6] Build the development image (if it doesn't exist))
	@$(call log-step,[Step 4/6] Create and start a container for building the app)
	@$(call log-step,[Step 5/6] Create an optimized production build)
	@$(call log-step,[Step 6/6] Stop and remove the container)
	@docker-compose run --rm ${SERVICE_APP} build
	@$(call log-info,The production build has been created successfully in $(call log-bold,./${DIR_BUILD}) directory)
	@ls ${DIR_BUILD}
	@$(txt-done)

.PHONY: preview
preview: ## Preview the production build locally
	@echo "Available options:"
	@echo "- Build image & preview  : press enter"
	@echo "- Rebuild image          : rebuild"
	@$(newline)
	@read -p "Enter the option: " option; \
	if [ "$$option" == "rebuild" ]; then \
		$(call function-preview,--build); \
	else \
		$(call function-preview); \
	fi;

##@ Utilities:

.PHONY: open
open: ## Open the app in the default browser *
	@echo "Available options:"
	@printf "1. $(call log-bold,dev) *    : Open the app running in the development environment.\n"
	@printf "2. $(call log-bold,build)    : Open an optimized production build locally.\n"
	@printf "3. $(call log-bold,staging)  : Unavailable!\n"
	@printf "4. $(call log-bold,live)     : Open the live app running in the production server.\n"
	@$(newline)
	@$(txt-options)
	@$(newline)
	@read -p "Enter the option: " option; \
	if [[ "$$option" == "" || "$$option" == 1 || "$$option" == "dev" ]]; then \
		$(call function-browser,${APP_URL_LOCAL}); \
	elif [[ "$$option" == 2 || "$$option" == "build" ]]; then \
		$(call function-browser,${APP_URL_BUILD}); \
	elif [[ "$$option" == 3 || "$$option" == "staging" ]]; then \
		echo "Sorry, the staging URL is not available."; \
	elif [[ "$$option" == 4 || "$$option" == "live" ]]; then \
		$(call function-browser,${APP_URL_LIVE}); \
	elif [ "$$option" == 0 ]; then \
		$(txt-skipped); \
	else \
		$(txt-opps); \
	fi;

.PHONY: shell
shell: ## Attach an interactive shell to the development container
	@$(call log-start,Attaching an interactive shell to the development container...)
	@docker container exec -it ${IMAGE_REPO}-${SUFFIX_LOCAL} sh

.PHONY: format
format: ## Format code automatically
	@$(call log-start,Formatting code...)
	@$(call log-step,[Step 1/4] Build the development image (if needed))
	@$(call log-step,[Step 2/4] Create and start a container for formatting code)
	@$(call log-step,[Step 3/4] Format code)
	@$(call log-step,[Step 4/4] Remove the container)
	@docker-compose run --rm ${SERVICE_APP} format
	@$(txt-done)

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
	@$(call function-browser,${HOST_TEMP}/${FILE_TREEMAP})

.PHONY: setup
setup: ## Setup the development environment and install dependencies ***
	@$(call log-start,Setting up the development environment...)
	@$(call log-step,[Step 1/2] Install dependencies required for running on the development environment)
	@docker pull ${IMAGE_BASE_NGINX}
	@docker pull ${IMAGE_BASE_NODE}
	@docker pull ${IMAGE_BASE_PROXY}
	@$(call log-step,[Step 2/2] Set a custom domain for a self-signed SSL certificate)
	@$(call function-host,${APP_DOMAIN_LOCAL})
	@$(call function-host,${APP_DOMAIN_BUILD})
	@$(txt-done)

##@ Testing & Linting:

.PHONY: test
test: ## Run tests *
	@echo "Available modes:"
	@printf "1. $(call log-bold,watch) *  : Watch files for changes and rerun tests related to changed files.\n"
	@printf "2. $(call log-bold,silent)   : Prevent tests from printing messages through the console.\n"
	@printf "3. $(call log-bold,verbose)  : Display individual test results with the test suite hierarchy.\n"
	@printf "4. $(call log-bold,coverage) : Generate code coverage reports (LCOV data).\n"
	@$(newline)
	@$(txt-options)
	@$(newline)
	@read -p "Enter test mode: " mode; \
	if [[ "$$mode" == "" || "$$mode" == 1 || "$$mode" == "watch" ]]; then \
		$(newline); \
		$(call log-start,Running tests in \"watch\" mode...) \
		$(call function-test); \
	elif [[ "$$mode" == 2 || "$$mode" == "silent" ]]; then \
		$(newline); \
		$(call log-start,Running tests in \"silent\" mode...) \
		$(call function-test,:silent); \
	elif [[ "$$mode" == 3 || "$$mode" == "verbose" ]]; then \
		$(newline); \
		$(call log-start,Running tests in \"verbose\" mode...) \
		$(call function-test,:verbose); \
	elif [[ "$$mode" == 4 || "$$mode" == "coverage" ]]; then \
		$(newline); \
		$(call log-start,Running tests and generate code coverage reports...) \
		$(call function-test,:coverage); \
		$(newline); \
		$(call log-sum,LCOV data is created in ${DIR_ROOT}${DIR_COVERAGE} directory) \
		ls ${DIR_COVERAGE}; \
		$(newline); \
		$(txt-done) \
	elif [ "$$mode" == 0 ]; then \
		$(txt-skipped); \
	else \
		$(txt-opps); \
	fi;

.PHONY: lint
lint: ## Run code linting *
	@echo "Available options:"
	@printf "1. $(call log-bold,script) *   : Lint JavaScript.\n"
	@printf "2. $(call log-bold,fix)        : Lint JavaScript and automatically fix problems.\n"
	@printf "3. $(call log-bold,stylesheet) : Lint Stylesheet (SCSS).\n"
	@$(newline)
	@$(txt-options)
	@$(newline)
	@read -p "Enter test mode: " mode; \
	if [[ "$$mode" == "" || "$$mode" == 1 || "$$mode" == "script" ]]; then \
		$(newline); \
		$(call log-start,Running JavaScript linting...) \
		$(call function-lint,:script); \
		$(txt-done) \
	elif [[ "$$mode" == 2 || "$$mode" == "fix" ]]; then \
		$(newline); \
		$(call log-start,Running JavaScript linting and trying to fix problems...) \
		$(call function-lint,:script:fix); \
		$(txt-done) \
	elif [[ "$$mode" == 3 || "$$mode" == "stylesheet" ]]; then \
		$(newline); \
		$(call log-start,Running Stylesheet linting...) \
		$(call function-lint,:stylesheet); \
		$(txt-done) \
	elif [ "$$mode" == 0 ]; then \
		$(txt-skipped); \
	else \
		$(txt-opps); \
	fi;

.PHONY: typecheck
typecheck: ## Run static type checking *
	@echo "Available options:"
	@printf "1. $(call log-bold,default) *  : Run a default check.\n"
	@printf "2. $(call log-bold,check)      : Run a full check and print the results.\n"
	@printf "3. $(call log-bold,focus)      : Run a focus check.\n"
	@printf "4. $(call log-bold,libdef)     : Update the library definitions (libdef).\n"
	@$(newline)
	@$(txt-options)
	@$(newline)
	@read -p "Enter the option: " option; \
	if [[ "$$option" == "" || "$$option" == 1 || "$$option" == "script" ]]; then \
		$(newline); \
		$(call log-start,Running static type checking...) \
		$(call function-typecheck); \
		$(txt-done) \
	elif [[ "$$option" == 2 || "$$option" == "check" ]]; then \
		$(newline); \
		$(call log-start,Running a full check and printing the results...) \
		$(call function-typecheck,:check); \
		$(txt-done) \
	elif [[ "$$option" == 3 || "$$option" == "focus" ]]; then \
		$(newline); \
		$(call log-start,Running a focus check...) \
		$(call function-typecheck,:check:focus); \
		$(txt-done) \
	elif [[ "$$option" == 4 || "$$option" == "libdef" ]]; then \
		$(call log-start,Updating the library definitions...) \
		$(call function-typecheck,:libdef); \
		$(call log-info,The library definitions have been updated$(,) please commit the changes in $(call log-bold,./${DIR_TYPED}) directory.) \
		$(txt-done) \
	elif [ "$$option" == 0 ]; then \
		$(txt-skipped); \
	else \
		$(txt-opps); \
	fi;

##@ Packages & Dependencies:

.PHONY: install
install: ## Install a package and any packages that it depends on **
	@read -p "Enter package name: " package; \
	if [ "$$package" != "" ]; then \
		$(call log-start,Installing npm package...) \
		$(call log-step,[Step 1/5] Build the development image (if needed)) \
		$(call log-step,[Step 2/5] Create and start a container for installing dependencies) \
		$(call log-step,[Step 3/5] Install $$package package in the persistent storage (volume)) \
		$(call log-step,[Step 4/5] Update package.json and yarn.lock) \
		$(call log-step,[Step 5/5] Remove the container) \
		docker-compose run --rm ${SERVICE_APP} add $$package; \
		$(txt-done) \
	else \
		echo "Skipped, you did not enter the package name, please try again"; \
	fi;

.PHONY: uninstall
uninstall: ## Uninstall a package **
	@read -p "Enter package name: " package; \
	if [ "$$package" != "" ]; then \
		$(call log-start,Uninstalling npm package...) \
		$(call log-step,[Step 1/5] Build the development image (if needed)) \
		$(call log-step,[Step 2/5] Create and start a container for uninstalling dependencies) \
		$(call log-step,[Step 3/5] Uninstall $$package package from the persistent storage (volume)) \
		$(call log-step,[Step 4/5] Update package.json and yarn.lock) \
		$(call log-step,[Step 5/5] Remove the container) \
		docker-compose run --rm ${SERVICE_APP} remove $$package; \
		$(txt-done) \
	else \
		echo "Skipped, you did not enter the package name, please try again"; \
	fi;

.PHONY: update
update: ## Install and update all the dependencies listed within package.json
	@$(function-update)
	@$(txt-done)

##@ Cleanup:

.PHONY: erase
erase: ## Clean up build artifacts and temporary files
	@$(call log-start,This command will perform the following actions:)
	@echo "- Remove all build artifacts"
	@echo "- Remove all temporary files"
	@$(newline)
	@printf "$(txt-note): You are about to permanently remove files and folders. You will not be able to recover these folders or their contents. $(call log-bold,This operation cannot be undone.)\n"
	@$(newline)
	@read -p "Remove build artifacts and temporary files? " confirmation; \
	case "$$confirmation" in \
		[yY] | [yY][eE][sS]) \
			$(newline); \
			$(call log-start,Removing data...) \
			$(call log-step,[Step 1/2] Remove build artifacts) \
			$(function-artifacts) \
			$(call log-step,[Step 2/2] Remove temporary files) \
			$(function-temporary) \
			$(newline); \
			$(call log-start,Listing the results...) \
			$(sum-artifacts) \
			$(newline); \
			$(sum-temporary) \
			$(newline); \
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
	@$(call log-start,This command will perform the following actions:)
	@echo "- Remove containers"
	@echo "- Remove the default network"
	@$(newline)
	@read -p "Refresh the development environment? " confirmation; \
	case "$$confirmation" in \
		[yY] | [yY][eE][sS]) \
			$(newline); \
			$(call log-start,Refreshing the development environment...) \
			$(call log-step,[Step 1/2] Stop and remove containers) \
			$(call log-step,[Step 2/2] Remove the default network) \
			docker-compose down; \
			$(newline); \
			$(call log-start,Listing the results...) \
			$(sum-docker) \
			$(newline); \
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
	@$(call log-start,This command will perform the following actions:)
	@echo "- Remove containers"
	@echo "- Remove the default network"
	@echo "- Remove volumes attached to containers"
	@$(newline)
	@printf "$(txt-note): You are about to permanently remove persistent data. $(call log-bold,This operation cannot be undone.)\n"
	@$(newline)
	@read -p "Clean up the development environment? " confirmation; \
	case "$$confirmation" in \
		[yY] | [yY][eE][sS]) \
			$(newline); \
			$(call log-start,Cleaning up the development environment...) \
			$(call log-step,[Step 1/3] Stop and remove containers) \
			$(call log-step,[Step 2/3] Remove the default network) \
			$(call log-step,[Step 3/3] Remove volumes attached to containers) \
			docker-compose down -v; \
			$(newline); \
			$(call log-start,Listing the results...) \
			$(sum-docker) \
			$(newline); \
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
	@$(call log-start,This command will perform the following actions:)
	@echo "- Remove containers, default network, and volumes attached to containers"
	@echo "- Remove the development image"
	@echo "- Remove the production image"
	@echo "- Remove the intermediate images"
	@echo "- Remove Remove all stopped containers (optional)"
	@echo "- Remove unused images (optional)"
	@echo "- Remove all unused local volumes (optional)"
	@echo "- Remove build artifacts"
	@echo "- Remove temporary files"
	@$(newline)
	@printf "$(txt-note): You are about to permanently remove files and folders. You will not be able to recover these folders or their contents. $(call log-bold,This operation cannot be undone.)\n"
	@$(newline)
	@read -p "Reset the development environment and clean up unused data? " confirmation; \
	case "$$confirmation" in \
		[yY] | [yY][eE][sS]) \
			$(newline); \
			$(call log-start,Resetting the development environment...) \
			$(call log-step,[Step 1/9] Stop and remove containers$(,) default network$(,) and volumes) \
			docker-compose down -v; \
			$(call log-step,[Step 2/9] Remove the development images) \
			docker image rm ${ENV_LOCAL}/${IMAGE_REPO}; \
			$(call log-step,[Step 3/9] Remove the production image) \
			docker image rm ${IMAGE_NAME}; \
			$(call log-step,[Step 4/9] Remove the intermediate images) \
			docker image prune --filter label=stage=${IMAGE_LABEL_INTERMEDIATE} --force; \
			$(call log-step,[Step 5/9] Remove all stopped containers (optional)) \
			docker container prune; \
			$(call log-step,[Step 6/9] Remove unused images (optional)) \
			docker image prune; \
			$(call log-step,[Step 7/9] Remove all unused local volumes (optional)) \
			docker volume prune; \
			$(call log-step,[Step 8/9] Remove build artifacts) \
			$(function-artifacts) \
			$(call log-step,[Step 9/9] Remove temporary files) \
			$(function-temporary) \
			$(newline); \
			$(call log-start,Listing the results...) \
			$(sum-docker) \
			$(newline); \
			$(sum-artifacts) \
			$(newline); \
			$(sum-temporary) \
			$(newline); \
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
	@$(call log-start,Setting the next release version...)
	@printf "The current version is $(call log-bold,v${RELEASE_VERSION}) (released on ${RELEASE_DATE})\n"
	@$(newline)
	@printf "$(txt-warning): You $(call log-bold,must) reset the development environment built with the configuration from v${RELEASE_VERSION} before tagging a new release version, otherwise you will not be able to remove the outdate environment once you have tagged a new version. To do that, cancel this command by hitting $(call log-bold,enter/return) key and run $(call log-bold,reset) command\n"
	@$(newline)
	@read -p "Enter a version number: " VERSION; \
	if [ "$$VERSION" != "" ]; then \
		printf "The next release will be $(call log-bold,v$$VERSION) on ${CURRENT_DATE} (today)\n"; \
		$(call set-env,RELEASE_DATE,${CURRENT_DATE},${CONFIG_ENV}); \
		$(call set-env,RELEASE_VERSION,$$VERSION,${CONFIG_ENV}); \
		rm ${CONFIG_ENV}.${EXT_BACKUP}; \
		$(txt-done) \
	else \
		$(txt-skipped); \
	fi;

.PHONY: release
release: ## Release new features
	@$(call log-start,Release new features)
	@$(function-release)
	@$(txt-done)

##@ Continuous Integration:

.PHONY: ci-update
ci-update: ## Install additional dependencies required for running on the CI environment
	@$(call log-start,Installing additional dependencies...)
	@$(call log-step,[Step 1/1] Update Docker Compose to version ${DOCKER_COMPOSE_VERSION})
	@sudo rm ${BINARY_PATH}/docker-compose
	@curl -L ${DOCKER_COMPOSE_REPO}/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > docker-compose
	@chmod +x docker-compose
	@sudo mv docker-compose ${BINARY_PATH}
	@$(txt-done)

.PHONY: ci-setup
ci-setup: ## Setup the CI environment and install required dependencies
	@$(call log-start,Setting up the CI environment...)
	@$(call log-step,[Step 1/2] Install dependencies required for running on the CI environment)
	@docker pull ${IMAGE_BASE_NGINX}
	@docker pull ${IMAGE_BASE_NODE}
	@$(call log-step,[Step 2/2] List downloaded Docker images)
	@docker image ls
	@$(txt-done)

.PHONY: ci-test
ci-test: ## Run tests and generate code coverage reports
	@$(call log-start,Running tests...)
	@$(call log-step,[Step 1/3] Build an image based on the development environment)
	@$(call log-step,[Step 2/3] Create and start a container for running tests)
	@$(call log-step,[Step 3/3] Run tests and generate code coverage reports)
	@docker-compose -f ${COMPOSE_BASE} -f ${COMPOSE_CI} up ${SERVICE_APP}
	@$(txt-done)

.PHONY: ci-coverage
ci-coverage: ## Create code coverage reports (LCOV format)
	@$(call log-start,Creating code coverage reports...)
	@$(call log-step,[Step 1/2] Copy LCOV data from the container\'s file system to the CI\'s)
	@docker cp ${CONTAINER_NAME_CI}:${CONTAINER_WORKDIR}/${DIR_COVERAGE} ${DIR_ROOT}
	@$(call log-step,[Step 2/2] Fix source paths in the LCOV file)
	@yarn replace ${CONTAINER_WORKDIR} ${TRAVIS_BUILD_DIR} ${LCOV_DATA} --silent
	@$(txt-done)

.PHONY: ci-deploy
ci-deploy: ## Create deployment configuration and build a production image
	@$(call log-start,Configuring a deployment configuration...)
	@$(function-release)
	@$(call log-start,Building a deployment configuration...)
	@$(call log-step,[Step 1/1] Build ${BUILD_ZIP} for uploading to AWS S3 service)
	@zip ${BUILD_ZIP} ${CONFIG_AWS}
	@$(call log-start,Building a production image (version ${RELEASE_VERSION}) for deployment...)
	@$(call log-step,[Step 1/3] Build the image)
	@docker-compose -f ${COMPOSE_BASE} -f ${COMPOSE_PRODUCTION} build ${SERVICE_APP}
	@$(call log-step,[Step 2/3] Login to Docker Hub)
	@echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
	@$(call log-step,[Step 3/3] Push the image to Docker Hub)
	@docker push ${IMAGE_NAME}
	@$(txt-done)

.PHONY: ci-coveralls
ci-coveralls: ## Send LCOV data (code coverage reports) to coveralls.io
	@$(call log-start,Sending LCOV data to coveralls.io...)
	@$(call log-step,[Step 1/2] Collect LCOV data from /coverage/lcov.info)
	@$(call log-step,[Step 2/2] Send the data to coveralls.io)
	@cat ${LCOV_DATA} | coveralls
	@$(txt-done)

.PHONY: ci-clean
ci-clean: ## Remove unused data from the CI server
	@$(call log-start,Removing unused data...)
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
	@$(call log-start,Listing system status...)
	@$(sum-docker)
	@$(newline)
	@$(call log-sum,The working tree status)
	@git status

.PHONY: help
help: ## Print usage
	@awk 'BEGIN {FS = ":.*##"; \
	printf "\nUsage: make \033[${ANSI_COLOR_CYAN}m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ \
	{ printf "  \033[${ANSI_COLOR_CYAN}m%-27s\033[0m %s\n", $$1, $$2 } /^##@/ \
	{ printf "\n\033[0m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@$(newline)
	@printf "*   with options\n"
	@printf "**  requires user input\n"
	@printf "*** requires superuser access\n\n"
