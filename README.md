# Docker Playground

[![Build Status](https://travis-ci.org/rxseven/onigiri-webapp.svg?branch=master)](https://travis-ci.org/rxseven/onigiri-webapp) [![Coverage Status](https://coveralls.io/repos/github/rxseven/onigiri-webapp/badge.svg)](https://coveralls.io/github/rxseven/onigiri-webapp) [![License: CC BY-NC-ND 4.0](https://img.shields.io/badge/License-CC%20BY--NC--ND%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-nd/4.0/) [![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

React & Redux single-page web application for collecting and organizing surveys.

With **Onigiri**, you can create and analyze surveys right in your pocket or web browser —no special software required. You get results as they come in and, you can summarize survey results at a glance with graphs.

> Onigiri (おにぎり) also known as rice ball, is a Japanese food made from white rice formed into triangular or cylindrical shapes and often wrapped in seaweed. For more information, see [Wikipedia](https://en.wikipedia.org/wiki/Onigiri).

## Table of Contents

- [Live Demo](#live-demo)
- [Development](#development)
- [Running the Production Build Locally](#running-the-production-build-locally)
- [Deploying a Single Docker Container to AWS Elastic Beanstalk](#Deploying-a-single-docker-container-to-aws-elastic-beanstalk)
- [Available Scripts](#available-scripts)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Development Workflow](#development-workflow)
- [Third-party services](#third-party-services)
- [Browser Support](#browser-support)
- [Related Projects](#related-projects)
- [Development Milestones](#development-milestones)
- [Changelog](#changelog)
- [Acknowledgements](#acknowledgements)
- [Credits](#credits)
- [Licenses](#licenses)

## Live Demo

Onigiri is hosted on Heroku at [https://onigiri-webapp.herokuapp.com](https://onigiri-webapp.herokuapp.com)

> **App sleeping...** as Onigiri and its API run on a free plan, when an app on Heroku has only one web dyno and that dyno doesn’t receive any traffic in 1 hour, the dyno goes to sleep. When someone accesses the app, the dyno manager will automatically wake up the web dyno to run the web process type. **This causes a short delay for this first request**, but subsequent requests will perform normally. For more information, see [App Sleeping on Heroku](https://blog.heroku.com/app_sleeping_on_heroku).

> **Daily limit** as Onigiri runs on a free plan, and the free trial is already expired, at which point, **Onigiri is restricted to sending 100 emails per day**. For more information, see [SendGrid Pricing & Plans](https://www.sendgrid.com/pricing/).

[Back to top](#table-of-contents)

## Development

### Prerequisites

#### Tools

Before getting started, you are required to have or install the following tools on your machine:

- [Git](https://git-scm.com) *(v2.17.2\*)*
- [GNU Bash](https://www.gnu.org/software/bash/) *(v3.2.57\*)*
- [GNU Make](https://www.gnu.org/software/make/) *(v3.8.1\*)*

> Note: if you are using Mac running [macOS](https://en.wikipedia.org/wiki/MacOS) *(v10.12 Sierra\*)*, you are all set.

Optional, but nice to have:

- [Visual Studio Code](https://code.visualstudio.com)\**
- [Google Chrome](https://www.google.com/chrome/)\**

#### Software as a Service

You also need to have to the following information:

- [Facebook app ID](https://developers.facebook.com/docs/apps/)
- [Google app ID](https://developers.google.com/identity/protocols/OAuth2)
- [Stripe publishable key](https://stripe.com/docs/keys)

#### Approach 1 : Docker

To make the development and testing work easier, Onigiri has a `Dockerfile` for development usage, which is based on the official [Node.js](https://hub.docker.com/_/node/) image, prepared with essential and useful tools for better development experience with best practices.

Below is the list of tools and services required for developing and running the containerized app on your machine:

- [Docker Community Edition](https://store.docker.com/search?type=edition&offering=community) *(v18.06.1\*)*
- [Docker ID account](https://docs.docker.com/docker-id/)

#### Approach 2 : nvm

Alternatively, if you would prefer not to use Docker, the following tools and libraries are required to be installed and configured on your machine:

- [nvm](https://github.com/creationix/nvm/releases/tag/v0.33.5) *(v0.33.5\*)* and [Node.js](https://nodejs.org/en/blog/release/v8.9.3/) *(v8.9.3\*)*
- [npm](https://github.com/npm/npm/releases/tag/v5.5.1) *(v5.5.1\*)* or [Yarn](https://github.com/yarnpkg/yarn/releases/tag/v1.3.2) *(v1.3.2\*)*

### Setup

**1.** Clone Onigiri Webapp from GitHub and change the current working directory:

```sh
git clone https://github.com/rxseven/onigiri-webapp.git
cd onigiri-webapp
```

**2.** Start [Docker](https://docs.docker.com/docker-for-mac/install/#install-and-run-docker-for-mac).

**3.** Setup the development environment:

```sh
make setup
```

> This command will take a few minutes (depending on your hardware) to complete configuring the development environment on your machine.

**4.** Open the project with your editor of choice or with Visual Studio Code:

```sh
make code
```

> Note: this command will open the project in Visual Studio Code directly from the command line. To enable this feature, please follow the further configuration steps described [here](https://code.visualstudio.com/docs/setup/mac#_launching-from-the-command-line).

**5.** Open `.env.development` file and add the configuration below:

```
REACT_APP_API_URL=https://onigiri-api.herokuapp.com
REACT_APP_WEB_URL=https://localhost:3000
REACT_APP_FACEBOOK_APP_ID=[FACEBOOK_APP_ID]
REACT_APP_GOOGLE_APP_ID=[GOOGLE_APP_ID]
REACT_APP_STRIPE_KEY=[STRIPE_PUBLIC_KEY]
```

### Starting the development and reverse proxy servers

**1.** Run the app by running the following command at the root of the project directory:

```sh
make start
```

This command will build a Docker image for development (if one doesn’t exist), create network and volume for persisting data, and start the development server (Webpack DevServer) along with reverse proxy server (Nginx).

**2.** Open [https://onigiri-webapp.local](https://onigiri-webapp.local), or run the command below to quickly launch the app in the default browser:

```sh
make open
```

> Note: the server will use a self-signed certificate, so your web browser will almost definitely display a warning upon accessing the page.

> Tip: press `control + c` to stop the running containers.

### Running shell in a running container

Run one of the following options to run Unix shell in a running container (**app** service):

```sh
make bash
make shell
```

> Tip: run `exit` inside a container to exit the shell.

### Installing & Uninstalling npm dependencies

Run one of the following commands and enter a package name:

```sh
make install
make uninstall
```

> Note: these commands will install/uninstall a package (and any packages that it depends on) in the persistent storage (volume) lather than the local `./node_module` directory on the host’s file system.

### Installing the dependencies listed within package.json

This command is used to install all dependencies for the project. This is most commonly used when you have just checked out code for the project, or when another developer on the project has added a new dependency that you need to pick up.

```sh
make update
```

### Running tests

**1.** Open `.env.test` file and add the configuration below:

```
REACT_APP_API_URL=https://onigiri-api.herokuapp.com
REACT_APP_WEB_URL=https://localhost:3000
REACT_APP_FACEBOOK_APP_ID=[FACEBOOK_APP_ID]
REACT_APP_GOOGLE_APP_ID=[GOOGLE_APP_ID]
REACT_APP_STRIPE_KEY=[STRIPE_PUBLIC_KEY]
```

**2.** Run the following command and enter the available options:

```sh
make test
```

1. Watch files for changes and rerun tests related to changed files
2. Prevent tests from printing messages through the console
3. Display individual test results with the test suite hierarchy
4. Generate code coverage reports (LCOV data)

> Note: by default, when you run test in *watch mode*, Jest will only run the tests related to files changed (modified) since the last commit. This is an optimization designed to make your tests run fast regardless of how many tests in the project you have. However, you can also press `a` in the watch mode to force Jest to run all tests.

> Note: code coverage reports will be generated in the local `./coverage` directory. This directory is listed in `.gitignore` file to ensure that it will not be tracked by Git.

> Tip: press `control + c` to stop the running tests.

### Running code linting

Run the following command and enter the available options:

```sh
make lint
```

1. Lint JavaScript
2. Lint JavaScript and automatically fix problems
3. Lint Stylesheet (SCSS)

### Running static type checking

Run the following command and enter the available options:

```sh
make typecheck
```

1. Run a default check
2. Run a full check and print the results
3. Run a focus check
4. Install and update the library definitions (libdef)

> Note: the library definitions will be installed in the local `./flow-typed` directory and must be committed to the source control.

### Formatting code automatically

Run the following command to format your code against Prettier and ESLint rules:

```sh
make format
```

### Creating an optimized production build

Run the command below to build the app for production. It correctly bundles the app in production mode and optimizes the build for the best performance. The build will be minified and the filenames include the hashes.

```sh
make build
```

> Note: the production build will be created in the local `./build` directory. This directory is listed in `.gitignore` file to ensure that it will not be tracked by Git.

### Analyzing the bundle size

To analyze and debug JavaScript and Sass code bloat through source maps, run the following command to create an optimized production build and start analyzing and debugging the bundle size:

```sh
make analyze
```

Once the analyzing process has finished and the report was generated, you will automatically be redirected to the browser displaying the treemap visualization of how the space is used in your minified bundle.

> Note: the production build and the treemap will be created/generated in the local `./build` and `./tmp` directories respectively.

### Using Git hooks

**ISSUE**: running scripts on any Git hooks in a Docker container is NOT POSSIBLE at the moment. To utilize this feature you have to rely on **nvm**.

[Back to top](#table-of-contents)

## Running the Production Build Locally

**1.** Run the following command to create an optimized production build and start a web server serving the app inside a container:

```sh
make preview
```

**2.** Open [https://onigiri-webapp](https://onigiri-webapp) in the browser, or run the command below to quickly launch the production app locally:

```sh
make open
```

> Note: the server will use a self-signed certificate, so your web browser will almost definitely display a warning upon accessing the page.

> Tip: press `control + c` to stop the running container.

[Back to top](#table-of-contents)

### Resetting the development environment

If your development environment doesn’t work properly, you may need to reset the environment with the commands below:

#### Refresh (soft clean)

```sh
make refresh
```

This command will remove containers and the default network.

#### Clean up (including persistent data)

```sh
make clean
```

This command will remove containers, the default network, and volumes attached to containers.

#### Reset and clean up unused data

```sh
make reset
```

This command will remove containers, the default network, volumes attached to containers, and local images (including development, production, and intermediate ones).

[Back to top](#table-of-contents)

## Deploying a Single Docker Container to AWS Elastic Beanstalk

[AWS Elastic Beanstalk](https://aws.amazon.com/elasticbeanstalk/) is an easy-to-use service offered from [Amazon Web Services](https://aws.amazon.com) for deploying and scaling web applications and services. You can simply upload your code and Elastic Beanstalk automatically handles the deployment, from capacity provisioning, load balancing, auto-scaling to application health monitoring.

### Prerequisites

#### Production environment

- 64bit Amazon Linux AMI *(2018.03.0 v2.12.3\*)*
- Docker Community Edition *(v18.06.1\*)*
- Nginx *(v1.12.1\*)*

> Note: for more information about **Single Container Docker** configuration, see [Elastic Beanstalk Supported Platforms](https://docs.aws.amazon.com/elasticbeanstalk/latest/platforms/platforms-supported.html).

#### Software as a Service

- [GitHub](https://github.com)
- [Travis CI](https://travis-ci.org)
- [Docker ID](https://docs.docker.com/docker-id/)
- [AWS Elastic Beanstalk](https://aws.amazon.com/elasticbeanstalk/)

### Setup

**1.** Create new [AWS Elastic Beanstalk environment](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.environments.html) and [AWS IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html).

**2.** Create `Dockkerrun.aws.json` file at the root of the project directory to deploy a Docker container from an existing Docker image to Elastic Beanstalk.

```sh
touch Dockkerrun.aws.json
```

A `Dockerrun.aws.json` file describes how to deploy a Docker container as an Elastic Beanstalk application. This JSON file is specific to Elastic Beanstalk.

```json
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "rxseven/onigiri-webapp:<TAG>",
    "Update": "true"
  },
  "Ports": [
    {
      "ContainerPort": "80"
    }
  ],
  "Logging": "/var/log/nginx"
}
```

> Note: for more information about single container Docker configuration, see [Single Container Docker Configuration](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create_deploy_docker_image.html).

**3.** On Travis CI’s repository settings screen, add two environment variables defining AWS IAM credentials as follows:

- `AWS_ACCESS_KEY`
- `AWS_SECRET_KEY`

> Note: for more information on defining variables in Travis CI’s repository settings, see [Environment Variables](https://docs.travis-ci.com/user/environment-variables#defining-variables-in-repository-settings).

**4.** Open `.travis.yml` and add the following code under `deploy` section:

```yml
# Deploy to AWS Elastic Beanstalk
- provider: elasticbeanstalk
  region: "<REGION>"
  app: "onigiri-webapp"
  env: "docker-env"
  bucket_name: "elasticbeanstalk-<REGION>-<ID>"
  bucket_path: "onigiri-webapp"
  skip_cleanup: true
  zip_file: ${BUILD_ZIP}
  on:
    branch: master
  access_key_id: ${AWS_ACCESS_KEY}
  secret_access_key:
    secure: ${AWS_SECRET_KEY}
```

> Note: for more information on deploying application to Elastic Beanstalk, see [AWS Elastic Beanstalk Deployment](https://docs.travis-ci.com/user/deployment/elasticbeanstalk/).

**5.** Update release version and image tag in the following files:

**.env**

```
RELEASE_VERSION=<VERSION>
```

**Dockerrun.aws.json**

```yml
"Name": "rxseven/onigiri-webapp:<TAG>"
```

**6.** Commit the changes and push to **GitHub**.

### Deployment

**1.** Create a pull request on GitHub and merge changes into `master` branch.

**2.** Once `master` branch has merged, **Travis CI** will build a production image, push the newly created image to **Docker Hub**, and deploy the app to running **AWS EC2** instances automatically.

**3.** **Elastic Beanstalk** will then pull the production image from **Docker Hub**, run a single Docker container, update web server environment, and deploy the latest updates.

[Back to top](#table-of-contents)

## Available Scripts

Onigiri contains a lengthy `Makefile`, to automate setup, installation, run, build, test, and deployment.

Most of the target names (script or task names) are standardized e.g. `make start`, `make install`, but some deserve explanation. The more we add fine-grained make targets, the more we need to describe what they do in text form.

Run the command below to print the usage and list all available scripts.

```sh
make
```

[Back to top](#table-of-contents)

## Features

### Authentication

Password-base and OAuth *(via third-party services, [Facebook](https://developers.facebook.com/products/account-creation) & [Google](https://cloud.google.com/))*

- Sign-up *(register)*
- Sign-in
- Sign-out
- JSON Web Token

### Users

- View user profile
- Delete user account

### Payments

- View credits
- Add credits, checkout, pay by credit card *(via third-party service, [Stripe](https://stripe.com/checkout))*

### Surveys

- Create survey *(and send emails)*
- View survey list *(with infinite scrolling functionality)*
- View survey details and statistics
- View recipient list
- Update survey *(mark as archive and/or complete)*
- Delete survey

### Emails and Statistics

- Send survey emails *(via third-party service, [SendGrid](https://sendgrid.com/))*
- Collect response data *(via webhook)*
- Update survey statistics

> Link: full details on Onigiri’s features and technical information are available [here](https://onigiri-webapp.herokuapp.com/about).

[Back to top](#table-of-contents)

## Technology Stack

Onigiri is built with [MERN](https://www.mongodb.com/blog/post/the-modern-application-stack-part-1-introducing-the-mean-stack) stack, one of the most popular stack of technologies for building a modern single-page app.

### Web application

- React, React Router, React Transition Group, Recompose
- Redux, Redux Saga, Redux Immutable, Redux Form, Reselect
- Lodash, Ramda, Axios, Immutable, Normalizr
- Sass, PostCSS, CSS modules, Bootstrap
- [More...](https://github.com/rxseven/onigiri-webapp/blob/master/package.json)

### RESTful API

- Node.js, Express, Passport, MongoDB, Mongoose
- Body parser, Path parser, Joi, Lodash
- Bcrypt.js, CORS, JSON Web Token
- SendGrid, Stripe, Gravatar
- [More...](https://github.com/rxseven/onigiri-api/blob/master/package.json)

> Link: RESTful API for Onigiri built with Node.js can be found in [this repository](https://github.com/rxseven/onigiri-api).

[Back to top](#table-of-contents)

## Development Workflow

- Project bootstraping with Create React App
- Development environment and app containerizing with Docker
- Development server, live reloading, and assets bundling with Webpack
- HTTP proxying with Nginx and self-signing SSL certificate with OpenSSL
- JavaScript transpiling with Babel
- CSS pre-processing and transforming with Sass, PostCSS, and CSS modules
- JavaScript linting with ESLint
- Stylesheet linting with Stylelint
- Code formatting with Prettier
- Automate testing with Jest and Enzyme
- Assets analyzing and debuging with Source Map Explorer
- Static type checking with Flow
- Code debugging with Visual Studio Code and Chrome Debugger
- Pre-commit hooking with Husky and Lint-staged
- CI/CD with GitHub, Travis CI, Coveralls, and Heroku

> Link: the complete guidelines are available in [this project](https://github.com/rxseven/setup-react-app).

[Back to top](#table-of-contents)

## Third-party services

### Infrastructure

- [Heroku](https://www.heroku.com/) - cloud platform as a service
- [AWS Elastic Beanstalk](https://aws.amazon.com/elasticbeanstalk/) - orchestration service for deploying infrastructure
- [mLab](https://mlab.com/) - database as a service for MongoDB

### Cloud computing and Platforms

- [SendGrid](https://sendgrid.com/) - cloud-based email
- [Stripe](https://stripe.com/checkout) - online payment platform
- [Facebook Platform](https://developers.facebook.com/products/account-creation) - social networking platform
- [Google Cloud Platform](https://cloud.google.com/) - cloud computing, Hosting, and APIs

### Software as a Service

- [GitHub](https://github.com/) - web-based hosting service for version control using Git
- [Travis CI](https://travis-ci.org/) - continuous integration
- [Coveralls](https://coveralls.io/) - test coverage history and statistics
- [Docker Hub](https://hub.docker.com) - cloud-based registry service for distributing container images

[Back to top](#table-of-contents)

## Browser Support

Because this project uses CSS3 features, it’s only meant for modern browsers. Some browsers currently fail to apply some of the styles correctly.

Chrome and Firefox have full support, but Safari and IE have strange behaviors.

[Back to top](#table-of-contents)

## Related Projects

**[Onigiri API](https://github.com/rxseven/onigiri-api)**

RESTful API for Onigiri built with Node.js, Express, Passport and MongoDB.

**[Setup React App](https://github.com/rxseven/setup-react-app)**

React & Redux starter kit with best practices bootstrapped with [Create React App](https://github.com/facebookincubator/create-react-app).

[Back to top](#table-of-contents)

## Development Milestones

- Setup Makefile *(in progress)*.
- Refactor code with functional programming principles *(in progress)*.
- Deploy the app on [DigitalOcean](https://www.digitalocean.com) or [Amazon Web Service (AWS)](https://aws.amazon.com).
- Implement components in isolation with [Storybook](https://storybook.js.org).
- Optimize the app’s performance.
- Add more unit tests and static type checking to cover the entire project *(in progress)*.

[Back to top](#table-of-contents)

## Changelog

See [releases](https://github.com/rxseven/onigiri-webapp/releases).

## Acknowledgements

This project is built and maintained by [Theerawat Pongsupawat](http://www.rxseven.com), frontend developer from Chiang Mai, Thailand.

## Credits

This project was bootstrapped with [Create React App](https://github.com/facebookincubator/create-react-app).

## Licenses

The content of this project itself is licensed under the [Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International license](http://creativecommons.org/licenses/by-nc-nd/4.0/), and the underlying source code is licensed under the [GNU AGPLv3 license](https://www.gnu.org/licenses/agpl-3.0).

---

\* the minimum required version or higher | ** the latest version
