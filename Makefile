# Dependencies
include .env

# Global variables
SHELL := /bin/bash
, := ,
blank :=
space := $(blank) $(blank)

# Condition cases
CASE_ANY := [nN] | [nN][oO] | *
CASE_NO  := [nN] | [nN][oO]
CASE_YES := [yY] | [yY][eE][sS]

# If statements
IF_CONTINUE := Are you sure you want to continue? [y/N]

# Date and time
CURRENT_DATE = $$(date +'%d.%m.%Y')

# ANSI Colors
ANSI_COLOR_BLACK := 30
ANSI_COLOR_BLUE := 34
ANSI_COLOR_CYAN := 36
ANSI_COLOR_GREEN := 32
ANSI_COLOR_MAGENTA := 35
ANSI_COLOR_RED := 31
ANSI_COLOR_YELLOW := 33
ANSI_COLOR_WHITE := 37

# Default goal
.DEFAULT_GOAL := help

# Loggers
log-bold = \e[1m$(1)\e[0m
log-complete = printf "\e[${ANSI_COLOR_GREEN}m$(1)\e[0m \n"
log-danger = $(call log-template,${ANSI_COLOR_RED},$(1))
log-info = $(call log-template,${ANSI_COLOR_WHITE},$(1))
log-italic = \e[3m$(1)\e[0m
log-process = printf "\e[${ANSI_COLOR_WHITE}m$(1)\e[0m \n"
log-result = $(call log-template,${ANSI_COLOR_MAGENTA},$(1))
log-start = $(call log-template,${ANSI_COLOR_MAGENTA},$(1))
log-step = $(call log-template,${ANSI_COLOR_YELLOW},$(1))
log-success = $(call log-template,${ANSI_COLOR_GREEN},$(1))
log-sum = $(call log-template,${ANSI_COLOR_CYAN},$(1))
log-template = printf "\e[100m make \e[${1};49m $(2)\e[0m \n"
log-underline = \e[4m$(1)\e[0m

# Text and string
newline = echo ""
headline = printf "\e[${ANSI_COLOR_CYAN};49;1m$(1)\e[0m \n\n"
txt-continue = echo "Continue to the next step..."
txt-diff = $(call log-sum,Changes between commits and working tree)
txt-done = $(call log-success,Done)
txt-note = $(call log-underline,Note)
txt-opps = echo "Opps! please try again."
txt-options = printf "* default option, press $(call log-bold,enter) key to continue / enter $(call log-bold,0) to cancel.\n"
txt-performing = echo "This command will perform the following actions:"
txt-processing = $(call log-process,Processing...)
txt-result = $(call log-result,Listing the results...)
txt-skipped = echo "Skipped"
txt-status = $(call log-sum,The working tree status)
txt-summary = $(call log-sum,Summary)
txt-version = printf "Makefile version ${MAKEFILE_VERSION}\n"
txt-warning = $(call log-underline,Warning)

# Getters and Setters
get-ip = $$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
set-json = sed -i.${EXT_BACKUP} 's|\(.*"$(1)"\): "\(.*\)"$(3).*|\1: '"\"$(2)\"$(3)|" $(4)
set-env = sed -i.${EXT_BACKUP} 's;^$(1)=.*;$(1)='"$(2)"';' $(3)

# Check if the specified image exists
define check-image
	docker image inspect $(1) >/dev/null 2>&1
endef

# Add host names
define helper-host
	if grep -Fxq "${HOST_IP}       $(1)" ${HOST_DNS}; then \
		echo "Skipping, $(1) is already set."; \
	else \
		echo "${HOST_IP}       $(1)" | sudo tee -a ${HOST_DNS}; \
		$(call log-complete,Set host name successfully.); \
	fi
endef

# Download image
define helper-image
	docker image inspect $(1) >/dev/null 2>&1 && \
	(echo "Skipping, $(1) already exists.") || \
	(docker pull $(1) && $(call log-complete,Downloaded successfully.))
endef

# Open a browser
define helper-browser
	printf "Opening $(call log-bold,$(1)) in the default browser...\n"; \
	open -a ${BROWSER} $(1); \
	$(txt-done)
endef

# Open Finder
define helper-finder
	printf "Opening $(call log-bold,$(1)) in Finder...\n"; \
	open $(1); \
	$(txt-done)
endef

# Build image for the CI environment
define helper-ci
	docker-compose -f ${COMPOSE_BASE} -f ${COMPOSE_CI} $(1) $(2) ${SERVICE_APP} $(3)
endef

# Create an optimized production build
define helper-production
	docker-compose -f ${COMPOSE_BASE} -f ${COMPOSE_PRODUCTION} $(1)
endef

# Run an optimized production build
define helper-preview
	$(newline); \
	$(call log-start,Run the production build...); \
	$(call log-step,[Step 1/8] Stop running containers *); \
	docker-compose stop; \
	$(call log-step,[Step 2/8] Create an optimized production build *); \
	$(call log-step,[Step 3/8] Build the production image tagged $(call log-bold,${IMAGE_NAME}) *); \
	$(call log-step,[Step 4/8] Create a network *); \
	$(call log-step,[Step 5/8] Create app and reverse proxy containers *); \
	$(call log-step,[Step 6/8] Start the containers); \
	$(call log-step,[Step 7/8] Attach STDOUT/STDERR and forward signals); \
	$(call log-step,[Step 8/8] Start the web and reverse proxy servers); \
	$(newline); \
	$(call log-info,Information); \
	printf "You can view the production build in the browser at:\n"; \
	$(newline); \
	printf "Local           : ${URL_BUILD}\n"; \
	printf "On your network : ${URL_PROTOCAL}://$(get-ip)\n"; \
	$(call check-image, ${IMAGE_NAME}) && ( \
		if [ "$(1)" == "build" ]; then \
			$(newline); \
			$(call log-start,Rebuilding the production image$(,) this will take a moment...); \
			$(call helper-production,up --build --no-start); \
		fi; \
	) || ( \
		$(newline); \
		$(call log-start,Building the production image$(,) this will take a moment...) && \
		$(call helper-production,up --no-start) \
	); \
	$(newline); \
	$(call log-start,Starting the containers...); \
	$(call helper-production,up)
endef

# Run tests
define helper-test
	$(call log-step,[Step 1/5] Remove the existing code coverage reports); \
	if [ "$(2)" == "cleanup" ]; then \
		$(remove-coverage); \
	else \
		echo "Skipping, this is not the case."; \
		$(txt-continue); \
	fi; \
	$(call log-step,[Step 2/5] Build the development image (if needed)); \
	$(call log-step,[Step 3/5] Create and start a container for running tests); \
	$(call log-step,[Step 4/5] Run tests); \
	$(call log-step,[Step 5/5] Remove the container when the process finishes); \
	docker-compose \
	-f ${COMPOSE_BASE} \
	-f ${COMPOSE_DEVELOPMENT} \
	-f ${COMPOSE_TEST} run \
	--name ${IMAGE_REPO}-${SUFFIX_TEST} \
	--rm \
	${SERVICE_APP} test$(1)
endef

# Open code coverage reports
define helper-coverage
	if [ -d "${DIR_COVERAGE}" ]; then \
		$(call helper-browser,./${DIR_COVERAGE}/lcov-report/index.html); \
	else \
		printf "Skipping, no code coverage reports found.\n"; \
		printf "Run $(call log-bold,test) command with $(call log-bold,coverage) option to generate the reports.\n"; \
	fi
endef

# Run linting
define helper-lint
	$(call log-step,[Step 1/4] Build the development image (if needed)); \
	$(call log-step,[Step 2/4] Create and start a container for running code linting); \
	$(call log-step,[Step 3/4] Run code linting); \
	$(call log-step,[Step 4/4] Remove the container when the process finishes); \
	docker-compose run --rm ${SERVICE_APP} lint$(1)
endef

# Run static type checking
define helper-typecheck
	$(call log-step,[Step 1/4] Build the development image (if needed)); \
	$(call log-step,[Step 2/4] Create and start a container for running static type checking); \
	$(call log-step,[Step 3/4] Run static type checking); \
	$(call log-step,[Step 4/4] Remove the container when the process finishes); \
	docker-compose run --rm ${SERVICE_APP} type$(1)
endef

# Commit changes
define helper-commit
	read -p "Would you like to commit the changes? " CONFIRMATION; \
	case "$$CONFIRMATION" in \
		${CASE_YES}) \
			$(newline); \
			$(call log-start,Preparing for the commit...); \
			git add $(1); \
			git status; \
			printf "The commit message will be \"$(2)\".\n"; \
			read -p "${IF_CONTINUE} " CONFIRMATION; \
			case "$$CONFIRMATION" in \
				${CASE_YES}) \
					$(newline); \
					$(call log-start,Committing the changes...); \
					git commit -m "$(2)"; \
					$(call log-complete,Committed successfully.); \
					$(newline); \
					$(txt-result); \
					$(call log-sum,The commit log); \
					git log -1 --stat; \
					$(newline); \
					$(call log-sum,Summary); \
					printf "$(4)\n"; \
				;; \
				${CASE_ANY}) \
					$(newline); \
					$(call log-start,Unstaging changes...); \
					git reset HEAD $(1); \
					echo $(3); \
				;; \
			esac; \
		;; \
		${CASE_ANY}) \
			echo $(3); \
		;; \
	esac
endef

# Release new application version
define helper-release
	$(call log-step,[Step 1/2] Configure ${CONFIG_AWS} for AWS Elastic Beanstalk deployment); \
	$(call set-json,Name,${IMAGE_NAME},$(,),${CONFIG_AWS}); \
	$(call set-json,ContainerPort,${PORT_PROXY},$(blank),${CONFIG_AWS}); \
	$(call log-step,[Step 2/2] Configure ${CONFIG_NPM} for AWS Node.js deployment); \
	$(call set-json,version,${RELEASE_VERSION},$(,),${CONFIG_NPM}); \
	rm *.${EXT_BACKUP}
endef

# Install and update dependencies
define helper-update
	$(call log-start,Install and update dependencies...)
	$(call log-step,[Step 1/7] Stop running containers *)
	docker-compose stop
	$(call log-step,[Step 2/7] Build the development image *)
	$(call log-step,[Step 3/7] Create a container for updating dependencies)
	$(call log-step,[Step 4/7] Start the container)
	$(call log-step,[Step 5/7] Install and update dependencies in the persistent storage (volume))
	$(call log-step,[Step 6/7] Update ${CONFIG_PACKAGE} *)
	$(call log-step,[Step 7/7] Remove the container)
	$(call check-image, ${IMAGE_DEVELOPMENT}) || ( \
		$(newline); \
		$(call log-start,Building the development image$(,) this will take a moment...) && \
		docker-compose build ${SERVICE_APP}; \
	); \
	$(newline); \
	$(call log-start,Installing dependencies...); \
	docker-compose run --rm ${SERVICE_APP} install
endef

# Rebuild image
define helper-up
	$(call log-step,[Step 1/3] Stop running containers (if ones exist)); \
	docker-compose stop; \
	$(call log-step,[Step 2/3] Download base images (if needed)); \
	$(call log-step,[Step 3/3] Rebuild the image(s)); \
	docker-compose build $(1)
endef

# Start development server
define helper-devserver
	read -p "Would you like to start the development server right away? " CONFIRMATION; \
	case "$$CONFIRMATION" in \
		${CASE_YES}) \
			$(newline); \
			$(helper-start); \
		;; \
		${CASE_ANY}) \
			$(txt-skipped); \
			$(txt-done); \
		;; \
	esac
endef

# Start development environment
define helper-start
	$(call log-start,Start the development environment...); \
	$(call log-step,[Step 1/8] Stop running containers *); \
	docker-compose stop; \
	$(call log-step,[Step 2/8] Build a development image *); \
	$(call log-step,[Step 3/8] Create a network *); \
	$(call log-step,[Step 4/8] Create a volume for persisting dependencies *); \
	$(call log-step,[Step 5/8] Create development and reverse proxy containers *); \
	$(call log-step,[Step 6/8] Start the containers); \
	$(call log-step,[Step 7/8] Attach STDOUT/STDERR and forward signals); \
	$(call log-step,[Step 8/8] Start the development and reverse proxy servers); \
	$(newline); \
	$(call log-info,Information); \
	printf "You can view $(call log-bold,${APP_NAME}) in the browser at:\n"; \
	$(newline); \
	printf "Local           : ${URL_LOCAL}\n"; \
	printf "On your network : ${URL_PROTOCAL}://$(get-ip)\n"; \
	$(newline); \
	printf "$(txt-note): DO NOT use the URLs, IP addresses and ports generated by Webpack DevServer\nshowing in the output below. They can only be accessible inside a container and\nare not bound to the host machine.\n"; \
	$(call check-image, ${IMAGE_DEVELOPMENT}) || ( \
		$(newline); \
		$(call log-start,Building the development image$(,) this will take a moment...) && \
		docker-compose up --no-start \
	); \
	$(newline); \
	$(call log-start,Starting the containers...); \
	docker-compose up
endef

# Set a new release version
define helper-version
	$(call log-start,Set a release version); \
	printf "The current version is $(call log-bold,v${RELEASE_VERSION}) (released on ${RELEASE_DATE})\n"; \
	$(newline); \
	printf "$(txt-note): You $(call log-bold,must) clean up the development environment built with the configuration\nfrom v${RELEASE_VERSION} before tagging a new release version, otherwise you will not be able\nto remove the outdated environment once you have set a new version. To do that,\ncancel this command by hitting $(call log-bold,enter/return) key and run $(call log-bold,reset) command.\n"; \
	$(newline); \
	read -p "Would you like to clean up the development environment? " CONFIRMATION; \
	case "$$CONFIRMATION" in \
		${CASE_YES}) \
			$(newline); \
			$(call log-start,Cleaning up the development environment...); \
			$(call log-step,[Step 1/4] Stop and remove containers$(,) default network$(,) and volumes); \
			docker-compose down -v; \
			$(call log-step,[Step 2/4] Remove the development images); \
			docker image rm ${ENV_LOCAL}/${IMAGE_REPO}; \
			$(call log-step,[Step 3/4] Remove the production image); \
			docker image rm ${IMAGE_NAME}; \
			$(call log-step,[Step 4/4] Remove the intermediate images); \
			docker image prune --filter label=stage=${IMAGE_LABEL_INTERMEDIATE} --force; \
			$(call log-complete,Cleaned up successfully.); \
			$(newline); \
			read -p "Enter a version number: " VERSION; \
			if [ "$$VERSION" != "" ]; then \
				GIT_CHANGES=${CONFIG_ENV}; \
				GIT_COMMIT="Set release version to v$$VERSION"; \
				TXT_INSTRUCTION="Skipping, please commit the changes before releasing the update."; \
				TXT_SUMMARY="Please run $(call log-bold,release) command to prepare for the next release."; \
				$(newline); \
				$(call log-start,Processing...); \
				$(call log-step,[Step 1/2] Set release date); \
				$(call set-env,RELEASE_DATE,${CURRENT_DATE},${CONFIG_ENV}); \
				echo "${CURRENT_DATE} (today)"; \
				$(call log-step,[Step 2/2] Set release version); \
				echo "v$$VERSION"; \
				$(call set-env,RELEASE_VERSION,$$VERSION,${CONFIG_ENV}); \
				rm ${CONFIG_ENV}.${EXT_BACKUP}; \
				$(call log-complete,Set a new version successfully.); \
				$(newline); \
				$(txt-result); \
				$(txt-status); \
				git status ${CONFIG_ENV}; \
				$(newline); \
				$(txt-diff); \
				git diff ${CONFIG_ENV}; \
				$(newline); \
				$(txt-summary); \
				printf "The next release will be $(call log-bold,v$$VERSION) on ${CURRENT_DATE} (today).\n"; \
				$(call helper-commit,$$GIT_CHANGES,$$GIT_COMMIT,$$TXT_INSTRUCTION,$$TXT_SUMMARY); \
				$(txt-done); \
			else \
				$(txt-skipped); \
			fi; \
		;; \
		${CASE_ANY}) \
			$(txt-skipped); \
		;; \
	esac
endef

# Open code editor
helper-code = code ${DIR_CWD}

# Remove build artifacts
define remove-build
	$(call log-process,Removing build artifacts...); \
	if [ -d "${DIR_BUILD}" ]; then \
		rm -rf -v ${DIR_BUILD}; \
		$(call log-complete,Removed successfully.); \
	else \
		echo "Skipping, no build artifacts found."; \
		$(txt-continue); \
	fi
endef

# Remove code coverage reports
define remove-coverage
	$(call log-process,Removing code coverage reports...); \
	if [ -d "${DIR_COVERAGE}" ]; then \
		rm -rf -v ${DIR_COVERAGE}; \
		$(call log-complete,Removed successfully.); \
	else \
		echo "Skipping, no code coverage reports found."; \
		$(txt-continue); \
	fi
endef

# Remove artifacts
define remove-artifacts
	if [[ -d "${DIR_BUILD}" || -d "${DIR_COVERAGE}" ]]; then \
		$(remove-build); \
		$(remove-coverage); \
	else \
		$(call log-process,Removing artifacts...); \
		echo "Skipping, no artifacts found."; \
		$(txt-continue); \
	fi
endef

# Remove temporary files
define remove-temporary
	$(call log-process,Removing temporary files...); \
	for f in ${DIR_TEMP}/*; do \
		[ -e "$$f" ] && \
		(rm -rf -v ${DIR_TEMP}/* && $(call log-complete,Removed successfully.)) || \
		(printf "Skipping, no temporary files found.\n" && $(txt-continue)); \
		break; \
	done
endef

# Git user settings
define git-user
	printf "Username : "; \
	git config user.name; \
	printf "Email    : "; \
	git config user.email
endef

# Docker summary
define sum-docker
	$(call log-sum,Containers (including exited state)); \
	docker container ls -a; \
	$(newline); \
	$(call log-sum,Networks); \
	docker network ls; \
	$(newline); \
	$(call log-sum,Volumes); \
	docker volume ls; \
	$(newline); \
	$(call log-sum,Images (including intermediates)); \
	docker image ls -a
endef

# Artifacts summary
define sum-artifacts
	$(call log-sum,Artifacts); \
	if [[ -d "${DIR_BUILD}" || -d "${DIR_COVERAGE}" ]]; then \
		echo "Opps! there are some artifacts left, please try again."; \
	else \
		echo "All clean"; \
	fi
endef

# Temporary files summary
define sum-temporary
	$(call log-sum,Temporary files); \
	for f in ${DIR_TEMP}/*; do \
		[ -e "$$f" ] && \
		echo "Opps! there are some files left, please try again." || \
		echo "All clean"; \
		break; \
	done
endef

##@ Development:

.PHONY: start
start: ## Start the development environment and attach to containers for a service
	@$(helper-start)

.PHONY: restart
restart: ## Rebuild and restart the development environment
	@$(call log-start,Restarting the development environment...)
	@$(call log-step,[Step 1/7] Stop running containers (if any))
	@docker-compose stop
	@$(call log-step,[Step 2/7] Download base images (if needed))
	@$(call log-step,[Step 3/7] Rebuild the development image)
	@$(call log-step,[Step 4/7] Create the development and reverse proxy containers)
	@$(call log-step,[Step 5/7] Start the containers)
	@$(call log-step,[Step 6/7] Attach STDOUT/STDERR and forward signals)
	@$(call log-step,[Step 7/7] Start the development and reverse proxy servers)
	@$(call log-info,You can view $(call log-bold,${APP_NAME}) in the browser at $(call log-bold,${URL_LOCAL}).)
	@docker-compose up --build

.PHONY: stop
stop: ## Stop running containers without removing them
	@$(call log-start,Stopping running containers...)
	@docker-compose stop
	@$(txt-done)

.PHONY: run
run: ## Update dependencies and start the development environment
	@$(call log-start,Update dependencies and start the development environment)
	@printf "Install and update all the dependencies listed within $(call log-italic,package.json) and $(call log-italic,yarn.lock)\nbefore starting the development environment.\n"
	@$(newline)
	@$(call log-info,Part 1/2 : Install and update dependencies)
	@$(helper-update)
	@$(newline)
	@$(call log-info,Part 2/2 : Start the development environment)
	@$(helper-start)

.PHONY: up
up: ## Rebuild images for the development environment services
	@$(call log-start,This command will perform the following actions:)
	@echo "- Stop running containers (if ones exist)"
	@echo "- Rebuild images for the development environment services"
	@$(newline)
	@echo "Available options:"
	@printf "1. $(call log-bold,all) *  : Rebuild images for all services\n"
	@printf "2. $(call log-bold,app)    : Rebuild image for app service\n"
	@printf "3. $(call log-bold,proxy)  : Rebuild image for proxy service\n"
	@$(newline)
	@$(txt-options)
	@$(newline)
	@read -p "Enter the option: " OPTION; \
	if [[ "$$OPTION" == "" || "$$OPTION" == 1 || "$$OPTION" == "all" ]]; then \
		$(newline); \
		$(call log-start,Rebuilding images for all services...); \
		$(call helper-up); \
		$(txt-done); \
	elif [[ "$$OPTION" == 2 || "$$OPTION" == "app" ]]; then \
		$(newline); \
		$(call log-start,Rebuilding image for ${SERVICE_APP} service...); \
		$(call helper-up,${SERVICE_APP}); \
		$(txt-done); \
	elif [[ "$$OPTION" == 3 || "$$OPTION" == "proxy" ]]; then \
		printf "Skipping, $(call log-bold,${SERVICE_PROXY}) service uses an image.\n"; \
	elif [ "$$OPTION" == 0 ]; then \
		$(txt-skipped); \
	else \
		$(txt-opps); \
	fi;

.PHONY: build
build: ## Create an optimized production build
	@$(call log-start,Creating an optimized production build...)
	@$(call log-step,[Step 1/6] Remove the existing build (if one exists))
	@$(remove-build)
	@$(call log-step,[Step 2/6] Download base images (if needed))
	@$(call log-step,[Step 3/6] Build the development image (if it doesn't exist))
	@$(call log-step,[Step 4/6] Create and start a container for building the app)
	@$(call log-step,[Step 5/6] Create an optimized production build)
	@$(call log-step,[Step 6/6] Stop and remove the container)
	@docker-compose run --rm ${SERVICE_APP} build
	@$(newline)
	@$(txt-result)
	@$(call log-sum,Build artifacts)
	@ls ${DIR_BUILD}
	@$(newline)
	@$(txt-summary)
	@printf "The production build has been created successfully in $(call log-bold,./${DIR_BUILD}) directory.\n"
	@read -p "Would you like to view the build artifacts in Finder? " CONFIRMATION; \
	case "$$CONFIRMATION" in \
		${CASE_YES}) \
			echo "Opening in Finder..."; \
			open ./${DIR_BUILD}; \
		;; \
		${CASE_ANY}) \
			$(txt-skipped); \
		;; \
	esac
	@$(txt-done)

.PHONY: preview
preview: ## Run the production build locally
	@echo "Available options:"
	@printf "1. $(call log-bold,run) *  : Run the production build\n"
	@printf "2. $(call log-bold,build)  : Build image before running the app\n"
	@$(newline)
	@$(txt-options)
	@$(newline)
	@read -p "Enter the option: " OPTION; \
	if [[ "$$OPTION" == "" || "$$OPTION" == 1 || "$$OPTION" == "run" ]]; then \
		$(call helper-preview); \
	elif [[ "$$OPTION" == 2 || "$$OPTION" == "build" ]]; then \
		$(call helper-preview,build); \
	elif [ "$$OPTION" == 0 ]; then \
		$(txt-skipped); \
	else \
		$(txt-opps); \
	fi;

##@ Testing & Linting:

.PHONY: test
test: ## Run tests *
	@echo "Available modes:"
	@printf "1. $(call log-bold,watch) *  : Watch files for changes and rerun tests related to changed files\n"
	@printf "2. $(call log-bold,silent)   : Prevent tests from printing messages through the console\n"
	@printf "3. $(call log-bold,verbose)  : Display individual test results with the test suite hierarchy\n"
	@printf "4. $(call log-bold,coverage) : Generate code coverage reports (LCOV data)\n"
	@$(newline)
	@$(txt-options)
	@$(newline)
	@read -p "Enter test mode: " MODE; \
	if [[ "$$MODE" == "" || "$$MODE" == 1 || "$$MODE" == "watch" ]]; then \
		$(newline); \
		$(call log-start,Running tests in \"watch\" mode...); \
		$(call helper-test); \
	elif [[ "$$MODE" == 2 || "$$MODE" == "silent" ]]; then \
		$(newline); \
		$(call log-start,Running tests in \"silent\" mode...); \
		$(call helper-test,:silent); \
	elif [[ "$$MODE" == 3 || "$$MODE" == "verbose" ]]; then \
		$(newline); \
		$(call log-start,Running tests in \"verbose\" mode...); \
		$(call helper-test,:verbose); \
	elif [[ "$$MODE" == 4 || "$$MODE" == "coverage" ]]; then \
		$(newline); \
		$(call log-start,Running tests and generate code coverage reports...); \
		$(call helper-test,:coverage,cleanup); \
		$(newline); \
		$(txt-result); \
		$(call log-sum,Code coverage reports); \
		ls ${DIR_COVERAGE}; \
		$(newline); \
		$(txt-summary); \
		printf "Code coverage reports have been generated in $(call log-bold,${DIR_ROOT}${DIR_COVERAGE}) directory.\n"; \
		read -p "Would you like to view the report visualization in the browser? " CONFIRMATION; \
		case "$$CONFIRMATION" in \
			${CASE_YES}) \
				$(helper-coverage); \
			;; \
			${CASE_ANY}) \
				printf "Skipping, you can view the reports later by running $(call log-bold,report) command.\n"; \
				$(txt-done); \
			;; \
		esac; \
	elif [ "$$MODE" == 0 ]; then \
		$(txt-skipped); \
	else \
		$(txt-opps); \
	fi;

.PHONY: lint
lint: ## Run code linting *
	@echo "Available options:"
	@printf "1. $(call log-bold,script) *   : Lint JavaScript\n"
	@printf "2. $(call log-bold,fix)        : Lint JavaScript and automatically fix problems\n"
	@printf "3. $(call log-bold,stylesheet) : Lint Stylesheet (SCSS)\n"
	@$(newline)
	@$(txt-options)
	@$(newline)
	@read -p "Enter test mode: " MODE; \
	if [[ "$$MODE" == "" || "$$MODE" == 1 || "$$MODE" == "script" ]]; then \
		$(newline); \
		$(call log-start,Running JavaScript linting...); \
		$(call helper-lint,:script); \
		$(txt-done); \
	elif [[ "$$MODE" == 2 || "$$MODE" == "fix" ]]; then \
		$(newline); \
		$(call log-start,Running JavaScript linting and trying to fix problems...); \
		$(call helper-lint,:script:fix); \
		$(txt-done); \
	elif [[ "$$MODE" == 3 || "$$MODE" == "stylesheet" ]]; then \
		$(newline); \
		$(call log-start,Running Stylesheet linting...); \
		$(call helper-lint,:stylesheet); \
		$(txt-done); \
	elif [ "$$MODE" == 0 ]; then \
		$(txt-skipped); \
	else \
		$(txt-opps); \
	fi;

.PHONY: typecheck
typecheck: ## Run static type checking *
	@echo "Available options:"
	@printf "1. $(call log-bold,default) *  : Run a default check\n"
	@printf "2. $(call log-bold,check)      : Run a full check and print the results\n"
	@printf "3. $(call log-bold,focus)      : Run a focus check\n"
	@printf "4. $(call log-bold,libdef)     : Update the library definitions (libdef)\n"
	@$(newline)
	@$(txt-options)
	@$(newline)
	@read -p "Enter the option: " OPTION; \
	if [[ "$$OPTION" == "" || "$$OPTION" == 1 || "$$OPTION" == "script" ]]; then \
		$(newline); \
		$(call log-start,Running static type checking...); \
		$(call helper-typecheck); \
		$(txt-done); \
	elif [[ "$$OPTION" == 2 || "$$OPTION" == "check" ]]; then \
		$(newline); \
		$(call log-start,Running a full check and printing the results...); \
		$(call helper-typecheck,:check); \
		$(txt-done); \
	elif [[ "$$OPTION" == 3 || "$$OPTION" == "focus" ]]; then \
		$(newline); \
		$(call log-start,Running a focus check...); \
		$(call helper-typecheck,:check:focus); \
		$(txt-done); \
	elif [[ "$$OPTION" == 4 || "$$OPTION" == "libdef" ]]; then \
		$(newline); \
		$(call log-start,Updating the library definitions...); \
		$(call helper-typecheck,:libdef); \
		$(newline); \
		$(txt-result); \
		$(txt-status); \
		git status ${DIR_TYPED}; \
		$(newline); \
		$(txt-summary); \
		printf "The library definitions have been installed in $(call log-bold,./${DIR_TYPED}) directory.\n"; \
		printf "Please commit the changes (if any).\n"; \
		$(txt-done); \
	elif [ "$$OPTION" == 0 ]; then \
		$(txt-skipped); \
	else \
		$(txt-opps); \
	fi;

##@ Statistics & Reports:

.PHONY: analyze
analyze: CONTAINER_NAME = ${IMAGE_REPO}-analyzing
analyze: build ## Analyze and debug code bloat through source maps
	@$(newline)
	@$(call log-start,Analyzing and debugging code...)
	@$(call log-step,[Step 1/5] Create and start a container for analyzing the bundle)
	@$(call log-step,[Step 2/5] Analyze the bundle size)
	@docker-compose run --name ${CONTAINER_NAME} ${SERVICE_APP} analyze
	@$(call log-step,[Step 3/5] Copy the result from the container's file system to the host's)
	@docker cp ${CONTAINER_NAME}:${CONTAINER_TEMP}/. ${HOST_TEMP}
	@ls ${HOST_TEMP}
	@$(call log-step,[Step 4/5] Remove the container)
	@docker container rm ${CONTAINER_NAME}
	@$(call log-step,[Step 5/5] Open the treemap visualization in the browser)
	@$(call helper-browser,${HOST_TEMP}/${FILE_TREEMAP})

.PHONY: report
report: ## Show development statistics and reports *
	@echo "Available options:"
	@printf "1. $(call log-bold,coverage) * : Open code coverage reports in the browser\n"
	@printf "2. $(call log-bold,none)       : Unavailable!\n"
	@$(newline)
	@$(txt-options)
	@$(newline)
	@read -p "Enter the option: " OPTION; \
	if [[ "$$OPTION" == "" || "$$OPTION" == 1 || "$$OPTION" == "coverage" ]]; then \
		$(helper-coverage); \
	elif [[ "$$OPTION" == 2 || "$$OPTION" == "none" ]]; then \
		echo "Sorry, this option is not available."; \
	elif [ "$$OPTION" == 0 ]; then \
		$(txt-skipped); \
	else \
		$(txt-opps); \
	fi;

##@ Packages & Dependencies:

.PHONY: install
install: ## Install a package and any packages that it depends on **
	@read -p "Enter package name: " PACKAGE; \
	if [ "$$PACKAGE" != "" ]; then \
		$(newline); \
		$(call log-start,Installing npm package...); \
		$(call log-step,[Step 1/5] Build the development image (if needed)); \
		$(call log-step,[Step 2/5] Create and start a container for installing dependencies); \
		$(call log-step,[Step 3/5] Install $$PACKAGE package in the persistent storage (volume)); \
		$(call log-step,[Step 4/5] Update ${CONFIG_NPM} and ${CONFIG_PACKAGE}); \
		$(call log-step,[Step 5/5] Remove the container); \
		docker-compose run --rm ${SERVICE_APP} add $$PACKAGE; \
		$(newline); \
		$(txt-result); \
		$(txt-diff); \
		git diff ${CONFIG_NPM}; \
		git diff ${CONFIG_PACKAGE}; \
		$(newline); \
		$(txt-status); \
		git status ${CONFIG_NPM} ${CONFIG_PACKAGE}; \
		$(newline); \
		$(txt-summary); \
		printf "The package has been installed successfully$(,) please commit the changes (if any).\n"; \
		$(newline); \
		$(txt-done); \
	else \
		echo "Skipping, you did not enter the package name, please try again."; \
	fi;

.PHONY: uninstall
uninstall: ## Uninstall a package **
	@read -p "Enter package name: " PACKAGE; \
	if [ "$$PACKAGE" != "" ]; then \
		$(newline); \
		$(call log-start,Uninstalling npm package...); \
		$(call log-step,[Step 1/5] Build the development image (if needed)); \
		$(call log-step,[Step 2/5] Create and start a container for uninstalling dependencies); \
		$(call log-step,[Step 3/5] Uninstall $$PACKAGE package from the persistent storage (volume)); \
		$(call log-step,[Step 4/5] Update ${CONFIG_NPM} and ${CONFIG_PACKAGE}); \
		$(call log-step,[Step 5/5] Remove the container); \
		docker-compose run --rm ${SERVICE_APP} remove $$PACKAGE; \
		$(newline); \
		$(txt-result); \
		$(txt-diff); \
		git diff ${CONFIG_NPM}; \
		git diff ${CONFIG_PACKAGE}; \
		$(newline); \
		$(txt-status); \
		git status ${CONFIG_NPM} ${CONFIG_PACKAGE}; \
		$(newline); \
		$(txt-summary); \
		printf "The package has been uninstalled successfully$(,) please commit the changes (if any).\n"; \
		$(newline); \
		$(txt-done); \
	else \
		echo "Skipping, you did not enter the package name, please try again."; \
	fi;

.PHONY: update
update: ## Install and update all the dependencies listed within package.json
	@$(helper-update)
	@$(newline)
	@$(helper-devserver)

##@ Cleanup:

.PHONY: erase
erase: ## Clean up artifacts and temporary files
	@$(call log-start,Clean up artifacts and temporary files)
	@$(txt-performing)
	@echo "- Remove all artifacts"
	@echo "- Remove all temporary files"
	@$(newline)
	@printf "$(txt-warning): You are about to permanently remove files. You will not be able to recover them. $(call log-bold,This operation cannot be undone.)\n"
	@$(newline)
	@read -p "${IF_CONTINUE} " CONFIRMATION; \
	case "$$CONFIRMATION" in \
		${CASE_YES}) \
			$(newline); \
			$(call log-start,Removing data...); \
			$(call log-step,[Step 1/2] Remove artifacts); \
			$(remove-artifacts); \
			$(call log-step,[Step 2/2] Remove temporary files); \
			$(remove-temporary); \
			$(newline); \
			$(txt-result); \
			$(sum-artifacts); \
			$(newline); \
			$(sum-temporary); \
			$(txt-done); \
		;; \
		${CASE_ANY}) \
			$(txt-skipped); \
		;; \
	esac

.PHONY: refresh
refresh: ## Refresh (soft clean) the development environment
	@$(call log-start,Refresh (soft clean) the development environment)
	@$(txt-performing)
	@echo "- Stop running containers"
	@echo "- Remove containers and the default network"
	@$(newline)
	@read -p "${IF_CONTINUE} " CONFIRMATION; \
	case "$$CONFIRMATION" in \
		${CASE_YES}) \
			$(newline); \
			$(call log-start,Refreshing the development environment...); \
			$(call log-step,[Step 1/2] Stop running containers); \
			$(call log-step,[Step 2/2] Remove containers and the default network); \
			docker-compose down; \
			$(newline); \
			$(txt-result); \
			$(sum-docker); \
			$(txt-done); \
		;; \
		${CASE_ANY}) \
			$(txt-skipped); \
		;; \
	esac

.PHONY: clean
clean: ## Clean up the development environment (including persistent data)
	@$(call log-start,Clean up the development environment)
	@$(txt-performing)
	@echo "- Stop running containers"
	@echo "- Remove containers"
	@echo "- Remove the default network"
	@echo "- Remove volumes attached to containers"
	@$(newline)
	@printf "$(txt-warning): You are about to permanently remove persistent data. $(call log-bold,This operation cannot be undone.)\n"
	@$(newline)
	@read -p "${IF_CONTINUE} " CONFIRMATION; \
	case "$$CONFIRMATION" in \
		${CASE_YES}) \
			$(newline); \
			$(call log-start,Cleaning up the development environment...); \
			$(call log-step,[Step 1/2] Stop running containers); \
			$(call log-step,[Step 2/2] Remove containers$(,) the default network$(,) and volumes); \
			docker-compose down -v; \
			$(newline); \
			$(txt-result); \
			$(sum-docker); \
			$(txt-done); \
		;; \
		${CASE_ANY}) \
			$(txt-skipped); \
		;; \
	esac

.PHONY: reset
reset: ## Reset the development environment and clean up unused data
	@$(call log-start,Reset the development environment and clean up unused data)
	@$(txt-performing)
	@echo "- Stop running containers"
	@echo "- Remove containers, default network, and volumes attached to containers"
	@echo "- Remove the development image"
	@echo "- Remove the production image"
	@echo "- Remove the intermediate images"
	@$(newline)
	@echo "Optional:"
	@echo "- Remove all stopped containers"
	@echo "- Remove unused images"
	@echo "- Remove all unused local volumes"
	@echo "- Remove artifacts"
	@echo "- Remove temporary files"
	@$(newline)
	@printf "$(txt-warning): You are about to permanently remove files. You will not be able to recover them. $(call log-bold,This operation cannot be undone.)\n"
	@$(newline)
	@read -p "${IF_CONTINUE} " CONFIRMATION; \
	case "$$CONFIRMATION" in \
		${CASE_YES}) \
			$(newline); \
			$(call log-start,Resetting the development environment...); \
			$(call log-step,[Step 1/9] Stop and remove containers$(,) default network$(,) and volumes); \
			docker-compose down -v; \
			$(call log-step,[Step 2/9] Remove the development images); \
			docker image rm ${ENV_LOCAL}/${IMAGE_REPO}; \
			$(call log-step,[Step 3/9] Remove the production image); \
			docker image rm ${IMAGE_NAME}; \
			$(call log-step,[Step 4/9] Remove the intermediate images); \
			docker image prune --filter label=stage=${IMAGE_LABEL_INTERMEDIATE} --force; \
			$(call log-step,[Step 5/9] Remove all stopped containers (optional)); \
			docker container prune; \
			$(call log-step,[Step 6/9] Remove unused images (optional)); \
			docker image prune; \
			$(call log-step,[Step 7/9] Remove all unused local volumes (optional)); \
			docker volume prune; \
			$(call log-step,[Step 8/9] Remove artifacts (optional)); \
			read -p "${IF_CONTINUE} " CONFIRMATION; \
			case "$$CONFIRMATION" in \
				${CASE_YES}) \
					$(remove-artifacts); \
				;; \
				${CASE_ANY}) \
					$(txt-skipped); \
				;; \
			esac; \
			$(call log-step,[Step 9/9] Remove temporary files (optional)); \
			read -p "${IF_CONTINUE} " CONFIRMATION; \
			case "$$CONFIRMATION" in \
				${CASE_YES}) \
					$(remove-temporary); \
				;; \
				${CASE_ANY}) \
					$(txt-skipped); \
				;; \
			esac; \
			$(newline); \
			$(txt-result); \
			$(sum-docker); \
			$(newline); \
			$(sum-artifacts); \
			$(newline); \
			$(sum-temporary); \
			$(txt-done); \
		;; \
		${CASE_ANY}) \
			$(txt-skipped); \
		;; \
	esac

##@ Utilities:

.PHONY: code
code: ## Open the project in the default code editor
	@$(call log-start,Opening the project in ${EDITOR}...)
	@$(helper-code)
	@$(txt-done)

.PHONY: open
open: ## Open the app in the default browser *
	@echo "Available options:"
	@printf "1. $(call log-bold,dev) *    : Open the app running in the development environment\n"
	@printf "2. $(call log-bold,build)    : Open an optimized production build locally\n"
	@printf "3. $(call log-bold,staging)  : Unavailable!\n"
	@printf "4. $(call log-bold,live)     : Open the live app running in the production server\n"
	@$(newline)
	@$(txt-options)
	@$(newline)
	@read -p "Enter the option: " OPTION; \
	if [[ "$$OPTION" == "" || "$$OPTION" == 1 || "$$OPTION" == "dev" ]]; then \
		$(newline); \
		$(call helper-browser,${URL_LOCAL}); \
	elif [[ "$$OPTION" == 2 || "$$OPTION" == "build" ]]; then \
		$(newline); \
		$(call helper-browser,${URL_BUILD}); \
	elif [[ "$$OPTION" == 3 || "$$OPTION" == "staging" ]]; then \
		echo "Sorry, the staging URL is not available."; \
	elif [[ "$$OPTION" == 4 || "$$OPTION" == "live" ]]; then \
		$(newline); \
		$(call helper-browser,${URL_LIVE}); \
	elif [ "$$OPTION" == 0 ]; then \
		$(txt-skipped); \
	else \
		$(txt-opps); \
	fi;

.PHONY: finder
finder: ## Open files and directories in Finder *
	@echo "Available options:"
	@printf "1. $(call log-bold,workspace) * : Open the working copy\n"
	@printf "2. $(call log-bold,backup)      : Open archived backup copies\n"
	@$(newline)
	@$(txt-options)
	@$(newline)
	@read -p "Enter the option: " OPTION; \
	if [[ "$$OPTION" == "" || "$$OPTION" == 1 || "$$OPTION" == "workspace" ]]; then \
		$(newline); \
		$(call helper-finder,${DIR_CWD}); \
	elif [[ "$$OPTION" == 2 || "$$OPTION" == "backup" ]]; then \
		$(newline); \
		$(call helper-finder,${DIR_BACKUP}); \
	elif [ "$$OPTION" == 0 ]; then \
		$(txt-skipped); \
	else \
		$(txt-opps); \
	fi;

.PHONY: shell
shell: ## Run Bourne shell in the app container
	@$(call log-start,Running Bourne shell in the app container...)
	@docker container exec -it ${IMAGE_REPO}-${SUFFIX_LOCAL} sh

.PHONY: bash
bash: ## Run Bash in the app container
	@$(call log-start,Running Bash in the app container...)
	@docker container exec -it ${IMAGE_REPO}-${SUFFIX_LOCAL} bash

.PHONY: format
format: ## Format code automatically
	@$(call log-start,Formatting code...)
	@$(call log-step,[Step 1/4] Build the development image (if needed))
	@$(call log-step,[Step 2/4] Create and start a container for formatting code)
	@$(call log-step,[Step 3/4] Format code)
	@$(call log-step,[Step 4/4] Remove the container)
	@docker-compose run --rm ${SERVICE_APP} format
	@$(newline)
	@$(txt-result)
	@$(txt-status)
	@git status | grep modified
	@$(newline)
	@read -p "Would you like to show changes between commits? " CONFIRMATION; \
	case "$$CONFIRMATION" in \
		${CASE_YES}) \
			$(txt-diff); \
			git diff; \
		;; \
		${CASE_ANY}) \
			$(txt-skipped); \
		;; \
	esac
	@$(txt-done)

.PHONY: setup
setup: GIT_CONFIG = ${DIR_GIT}/config
setup: ## Setup the development environment ***
	@$(call log-start,Setting up the development environment...)
	@$(call log-step,[Step 1/5] Configure Git username and email address)
	@if grep -Fxq "[user]" ${GIT_CONFIG}; then \
		echo "Your user settings are already set for this repository in ${GIT_CONFIG}:"; \
		$(newline); \
		$(git-user); \
	else \
		echo "The following are your global Git user settings:"; \
		$(newline); \
		$(git-user); \
		$(newline); \
		printf "$(txt-note): You can change the username and email address associated with commits\nyou make in this repository. This will override your global Git configuration\nsettings in this one repository, but will not affect any other repositories.\n"; \
	fi
	@$(newline)
	@read -p "Would you like to change the current settings? " CONFIRMATION; \
	case "$$CONFIRMATION" in \
		${CASE_YES}) \
			read -p "Enter new username: " USERNAME; \
			if [ "$$USERNAME" != "" ]; then \
				git config user.name "$$USERNAME"; \
			else \
				$(txt-skipped); \
			fi; \
			read -p "Enter new email address: " EMAIL; \
			if [ "$$EMAIL" != "" ]; then \
				git config user.email "$$EMAIL"; \
			else \
				$(txt-skipped); \
			fi; \
			$(call log-complete,Configured successfully.); \
		;; \
		${CASE_ANY}) \
			echo "Skipping, use the current settings."; \
		;; \
	esac
	@$(call log-step,[Step 2/5] Install dependencies required for running on the development environment)
	@$(call log-process,Checking local images...)
	@$(call helper-image,${BASE_NGINX})
	@$(call helper-image,${BASE_NODE})
	@$(call helper-image,${BASE_PROXY})
	@$(call log-step,[Step 3/5] Set custom host names for a self-signed SSL certificate)
	@$(call log-process,Verifying host names...)
	@$(call helper-host,${DOMAIN_LOCAL})
	@$(call helper-host,${DOMAIN_BUILD})
	@$(call log-step,[Step 4/5] Create a backup directory)
	@if [ -d ${DIR_BACKUP} ]; then \
  	echo "Skipping, the directory already exists."; \
	else \
		$(call log-process,Creating a backup directory...); \
		mkdir -p ${DIR_BACKUP}; \
		echo ${DIR_BACKUP}; \
		$(call log-complete,Created backup directory successfully.); \
	fi
	@$(call log-step,[Step 5/5] Build the development image)
	@docker-compose build ${SERVICE_APP}
	@$(call log-complete,Built successfully.)
	@$(newline)
	@$(txt-result)
	@$(call log-sum,Git user settings)
	@echo "The following information will be associated with commits you make in this repository:"
	@$(newline)
	@$(git-user)
	@$(newline)
	@$(call log-sum,Images)
	@docker image ls
	@$(newline)
	@$(call log-sum,Host names)
	@cat ${HOST_DNS}
	@$(newline)
	@$(call log-sum,Backup directory)
	@if [ -d ${DIR_BACKUP} ]; then \
		echo ${DIR_BACKUP}; \
	else \
		echo "Opps! the directory did not create properly, please try again."; \
	fi
	@$(newline)
	@$(call log-sum,Summary)
	@echo "You are all set."
	@$(helper-devserver)

.PHONY: backup
backup: BACKUP_DATE = $$(date +'%d.%m.%Y')
backup: BACKUP_TIME = $$(date +'%H.%M.%S')
backup: BACKUP_NAME = ${APP_NAME}-${BACKUP_DATE}-${BACKUP_TIME}.${EXT_ARCHIVE}
backup: ## Create a backup copy of the project
	@$(call log-start,Creating a backup copy...)
	@$(call log-step,[Step 1/2] Create a backup copy)
	@zip -r -q ${FILE_BACKUP} ${DIR_CWD} -x \
	.DS_Store \
	"${DIR_GIT}/*" \
	"${DIR_BUILD}/*" \
	"${DIR_COVERAGE}/*" \
	"${DIR_DEPENDENCIES}/*" \
	"${DIR_TEMP}/*";
	@$(call log-step,[Step 2/2] Upload the archive to the cloud storage)
	@mv ${FILE_BACKUP} ${DIR_BACKUP}/${BACKUP_NAME}
	@$(newline)
	@echo "Date     : ${BACKUP_DATE}"
	@echo "Time     : ${BACKUP_TIME}"
	@echo "Prefix   : ${APP_NAME}"
	@echo "Type     : ${EXT_ARCHIVE}"
	@echo "File     : ${BACKUP_NAME}"
	@echo "Location : ${DIR_BACKUP}"
	@$(newline)
	@$(txt-result)
	@$(call log-sum,Archived backup copies)
	@ls ${DIR_BACKUP}
	@$(newline)
	@$(txt-summary)
	@echo "The backup has been created and uploaded to the cloud storage."
	@read -p "Would you like to show archived backup copies? " CONFIRMATION; \
	case "$$CONFIRMATION" in \
		${CASE_YES}) \
			$(call helper-finder,${DIR_BACKUP}); \
		;; \
		${CASE_ANY}) \
			$(txt-skipped); \
			$(txt-done); \
		;; \
	esac

##@ Branching & Merging:

.PHONY: branch
branch: ## Create a new Git branch *
	@$(call log-start,Creating a new branch...)
	@if [[ $$(git diff --stat) != "" ]]; then \
		echo "Error: Your working tree is not clean."; \
		$(newline); \
		$(txt-result); \
		$(txt-status); \
		git status; \
		$(newline); \
		$(txt-summary); \
		echo "Please commit your changes or stash them before creating a new branch."; \
		echo "Aborting"; \
	else \
		$(call log-step,[Step 0/0] Create a new branch); \
		@read -p "Enter branch name: " BRANCH; \
		if [ "$$BRANCH" != "" ]; then \
			git checkout -b feature/$$BRANCH feature/playground; \
			git branch; \
			$(call log-step,[Step 0/0] Publish the newly created branch to the remote repository); \
			git push -u origin feature/$$BRANCH; \
			$(newline); \
			$(txt-result); \
			$(log-sum,Local branches); \
			git branch; \
			$(txt-status); \
			git status; \
			$(txt-summary); \
			echo "New branch has been created and published to the remote repository"; \
			$(txt-done); \	
		else \
			echo "Skipping, you did not enter the branch name, please try again."; \
		fi;	
	fi

##@ Operations:

.PHONY: version
version: ## Set a release version **
	@$(helper-version)

.PHONY: release
release: ## Release new update
	@$(call log-start,Preparing for a new release...)
	@if [[ `git diff ${CONFIG_ENV}` ]]; then \
		$(helper-release); \
		$(newline); \
		$(txt-result); \
		$(txt-status); \
		git status ${CONFIG_AWS} ${CONFIG_NPM}; \
		$(newline); \
		$(txt-diff); \
		git diff ${CONFIG_AWS}; \
		git diff ${CONFIG_NPM}; \
		$(newline); \
		$(txt-summary); \
		printf "Please commit the changes and merge into $(call log-bold,master) branch.\n"; \
		$(txt-done); \
	else \
		printf "Skipping, please run $(call log-bold,version) command before releasing the update.\n"; \
	fi;

##@ Continuous Integration:

.PHONY: ci-update
ci-update: ## Install and update dependencies required for running on the CI environment
	@$(call log-start,Installing and updating additional dependencies...)
	@$(call log-step,[Step 1/1] Update Docker Compose to v${PACKAGE_COMPOSE_VERSION})
	@sudo rm ${CONTAINER_BIN}/docker-compose
	@curl -L ${PACKAGE_COMPOSE_REPO}/${PACKAGE_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > docker-compose
	@chmod +x docker-compose
	@sudo mv docker-compose ${CONTAINER_BIN}
	@$(txt-done)

.PHONY: ci-setup
ci-setup: ## Setup the CI environment and install required dependencies
	@$(call log-start,Configuring the CI environment...)
	@$(call log-step,[Step 1/4] Install dependencies required for running on the CI environment)
	@docker pull ${BASE_NGINX}
	@docker pull ${BASE_NODE}
	@$(call log-step,[Step 2/4] List downloaded base images)
	@docker image ls
	@$(call log-step,[Step 3/4] Build image for running containers on the CI environment)
	@$(call helper-ci,build)
	@$(call log-step,[Step 4/4] List all images)
	@docker image ls	
	@$(txt-done)

.PHONY: ci-test
ci-test: ## Run tests and generate code coverage reports
	@$(call log-start,Running tests...)
	@$(call log-step,[Step 1/3] Create and start a container for running tests)
	@$(call log-step,[Step 2/3] Run tests)
	@$(call log-step,[Step 3/3] Generate code coverage reports)
	@$(call helper-ci,run,--name ${CONTAINER_NAME_CI} -e NODE_ENV=${ENV_TEST},test:coverage)
	@$(txt-done)

.PHONY: ci-scriptlint
ci-scriptlint: ## Run code linting
	@$(call log-start,Running code linting...)
	@$(call log-step,[Step 1/3] Create and start a container for running code linting)
	@$(call log-step,[Step 2/3] Run JavaScript linting)
	@$(call log-step,[Step 3/3] Remove the container when the process finishes); \
	@$(call helper-ci,run,--rm,lint:script)
	@$(txt-done)

.PHONY: ci-coverage
ci-coverage: ## Create code coverage data (LCOV format)
	@$(call log-start,Creating code coverage data...)
	@$(call log-step,[Step 1/2] Copy LCOV data from the container\'s file system to the CI\'s)
	@docker cp ${CONTAINER_NAME_CI}:${CONTAINER_WORKDIR}/${DIR_COVERAGE} ${DIR_ROOT}
	@$(call log-step,[Step 2/2] Fix incorrect source paths in the LCOV file)
	@yarn replace ${CONTAINER_WORKDIR} ${TRAVIS_BUILD_DIR} ${LCOV} --silent
	@$(txt-done)

.PHONY: ci-deploy
ci-deploy: ## Create deployment configuration and build a production image
	@$(call log-start,Configuring a deployment configuration...)
	@$(helper-release)
	@$(call log-start,Building a deployment configuration...)
	@$(call log-step,[Step 1/1] Build ${BUILD_ZIP} for uploading to AWS S3 service)
	@zip ${BUILD_ZIP} ${CONFIG_AWS}
	@$(call log-start,Building a production image (version ${RELEASE_VERSION}) for deployment...)
	@$(call log-step,[Step 1/3] Build the image)
	@$(call helper-production,build ${SERVICE_APP})
	@$(call log-step,[Step 2/3] Login to Docker Hub)
	@echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
	@$(call log-step,[Step 3/3] Push the image to Docker Hub)
	@docker push ${IMAGE_NAME}
	@$(txt-done)

.PHONY: ci-coveralls
ci-coveralls: ## Send LCOV data (code coverage) to coveralls.io
	@$(call log-start,Sending LCOV data to coveralls.io...)
	@$(call log-step,[Step 1/2] Collect LCOV data from ${DATA_LCOV})
	@$(call log-step,[Step 2/2] Send the data to coveralls.io)
	@cat ${DATA_LCOV} | coveralls
	@$(txt-done)

.PHONY: ci-clean
ci-clean: ## Remove unused data from the CI server
	@$(call log-start,Removing unused data...)
	@docker system prune --all --volumes --force
	@$(txt-done)

##@ Miscellaneous:

.PHONY: info
info: ## Show project configuration
	@$(call headline,Releases)
	@echo "Date                           : ${RELEASE_DATE}"
	@echo "Version                        : ${RELEASE_VERSION}"
	@$(newline)
	@$(call headline,App)
	@echo "Name                           : ${APP_NAME}"
	@echo "Repository                     : ${REPO_URL}"
	@echo "Live URL                       : ${URL_LIVE}"
	@$(newline)
	@$(call headline,Domain name & URLs)
	@echo "Protocal                       : ${URL_PROTOCAL}"
	@echo "Top level domain (TLD)         : ${DOMAIN_TLD}"
	@echo "Domain name                    : ${DOMAIN_NAME}"
	@echo "Development URL                : ${URL_LOCAL}"
	@echo "Production build URL           : ${URL_BUILD}"
	@$(newline)
	@$(call headline,Host machine)
	@echo "Hosts file                     : ${HOST_DNS}"
	@echo "Working directory              : $$PWD"
	@echo "Temporary path                 : ${HOST_TEMP}"
	@echo "IP address                     : ${HOST_IP}"
	@$(newline)
	@$(call headline,Base images)
	@echo "NGINX                          : ${BASE_NGINX}"
	@echo "Node.js                        : ${BASE_NODE}"
	@echo "Proxy                          : ${BASE_PROXY}"
	@$(newline)
	@$(call headline,Image & Container)
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
	@$(call headline,Configuration files)
	@echo "Amazon Web Services (AWS)      : ${CONFIG_AWS}"
	@echo "NPM & Yarn                     : ${CONFIG_NPM}"
	@echo "Travis CI                      : ${CONFIG_CI}"
	@echo "Environment variables          : ${CONFIG_ENV}"
	@$(newline)
	@$(call headline,Files & Directories)
	@echo "Optimized production build     : ${DIR_BUILD}"
	@echo "Code coverage                  : ${DIR_COVERAGE}"
	@echo "Temporary                      : ${DIR_TEMP}"
	@echo "Treemap                        : ${FILE_TREEMAP}"
	@$(newline)
	@$(call headline,Ports)
	@echo "Development server             : ${PORT_DEVSERVER}"
	@echo "Reverse proxy server           : ${PORT_PROXY}"
	@echo "Unsecured HTTP port mapping    : ${PORT_MAPPING_HTTP}"
	@echo "SSL port mapping               : ${PORT_MAPPING_SSL}"
	@$(newline)
	@$(call headline,Miscellaneous)
	@echo "Default browser                : ${BROWSER}"
	@echo "License                        : ${IMAGE_LICENSE}"
	@$(newline)
	@$(call headline,Maintainer)
	@echo "Name                           : ${AUTHOR_NAME}"
	@echo "Email                          : ${AUTHOR_EMAIL}"
	@$(newline)
	@$(txt-version)
	@$(newline)

.PHONY: status
status: ## Show system status
	@$(call log-start,Listing system status...)
	@$(sum-docker)
	@$(newline)
	@$(txt-status)
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
	@$(txt-version)
	@$(newline)
