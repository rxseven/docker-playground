# Specify global variables
ARG BUILD_ENV=development
ARG IMAGE_BASE_NODE

# Development stage
# Initialize a new build stage and set the base image
FROM ${IMAGE_BASE_NODE} as development

# Specify build and environment variables
ARG BUILD_ENV
ARG WORKDIR
ENV NODE_ENV=${BUILD_ENV}
ENV PATH /usr/src/app/node_modules/.bin:${PATH}

# Specify the working directory
WORKDIR ${WORKDIR}

# Install and update dependencies
COPY package.json yarn.lock ./
RUN yarn && yarn cache clean

# Copy the entire contents from the host and add them to the container
COPY . .

# Specify network ports
EXPOSE 3000

# Specify the default executable when a container is started
ENTRYPOINT ["yarn"]

# Provide defaults for an executing container
CMD ["start:https"]
