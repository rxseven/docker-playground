# Specify global variables
ARG BASE_NODE
ARG BUILD_ENV=development

# Development stage
# Initialize a new build stage and set the base image
FROM ${BASE_NODE} as development

# Specify build and environment variables
ARG BUILD_ENV
ARG DEPENDENCY_LIST
ARG DEPENDENCY_LOCK
ARG PORT_EXPOSE
ARG WORKDIR
ENV NODE_ENV=${BUILD_ENV}
ENV PATH /usr/src/app/node_modules/.bin:${PATH}

# Specify the working directory
WORKDIR ${WORKDIR}

# Install and update dependencies
COPY ${DEPENDENCY_LIST} ${DEPENDENCY_LOCK} ./
RUN yarn && yarn cache clean

# Copy the entire contents from the host and add them to the container
COPY . .

# Specify network ports
EXPOSE ${PORT_EXPOSE}

# Specify the default executable when a container is started
ENTRYPOINT ["yarn"]

# Provide defaults for an executing container
CMD ["start"]
