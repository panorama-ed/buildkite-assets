#!/bin/sh

set -o pipefail
set -e

echo "--- Preparing to run Panorama Command"

# If no argument was passed in
if [ -z "$1" ]; then
  echo "Please pass in a command, it can be one of the following:"
  echo
  echo " deploy              Deploys $DEPLOYMENT_APP_NAME"
  echo " db_migrate          Run DB migration for $DEPLOYMENT_APP_NAME"
  echo " custom {commands}   Runs a custom command that is passed in"
  echo
  exit 1
fi

# The default path is the location where the heroku-deploy folder lives
# on the Buildkite agent. For local testing, it's sometime helpful to have
# this available as an environment variable (you can set it to where
# heroku-deploy lives on your local machine, so that the scripts will run)
export HEROKU_DEPLOY_PATH=${HEROKU_DEPLOY_PATH:=/usr/local/bin/heroku-deploy}

# Build docker image
docker build \
  --build-arg buildkite_agent_uid=$UID \
  -t heroku-deploy-img \
  $HEROKU_DEPLOY_PATH

command=""

if [ $1 = "deploy" ]; then
  deploy_branch="main"

  echo "--- Deploying $DEPLOYMENT_APP_NAME to $deploy_branch"
  command="git push heroku $BUILDKITE_COMMIT:refs/heads/$deploy_branch"
elif [ $1 = "db_migrate" ]; then
  echo "--- Running DB Migration"
  command="heroku run --exit-code 'rake db:migrate' -a $DEPLOYMENT_APP_NAME"
elif [ $1 = "custom" ]; then
  echo "--- Running custom command: '${@:2}'"
  command="${@:2}"
fi

# run it
# in order for docker to work as expected, the docker daemon must be mounted
# when running the image
docker run \
  -e DEPLOYMENT_APP_NAME \
  -e HEROKU_DEPLOYMENT_LOGIN \
  -e HEROKU_DEPLOYMENT_API_KEY \
  -e BUILDKITE_COMMIT \
  -v `pwd`:/home/panorama/app \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -it heroku-deploy-img \
  $command
