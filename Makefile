# Phony targets
.PHONY: clean clean-all shell start start-build start-production test

# Stops containers, removes containers and the default network (if one is used)
clean:
	@docker-compose down

# Stops containers, removes containers, networks (if one is used), and volumes
clean-all:
	@docker-compose down -v

# Attaches an interactive shell to a running container
shell:
	@docker container exec -it playground-local sh

# Builds, (re)creates, starts, and attaches to containers for a service
start:
	@docker-compose up

# Builds images before starting development and reverse proxy containers
start-build:
	@docker-compose up --build

# Runs an optimized production build locally
start-production:
	@docker-compose \
	-f docker-compose.yml \
	-f docker-compose.production.yml \
	up

# Runs tests
test:
	@docker-compose \
	-f docker-compose.yml \
	-f docker-compose.override.yml \
	-f docker-compose.test.yml run \
	--name playground-test \
	--rm \
	app

# Default command
default: start
