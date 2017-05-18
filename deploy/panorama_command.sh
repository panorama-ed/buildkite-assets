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

# Build docker image
docker build \
  --build-arg buildkite_agent_uid=$UID \
  -t heroku-deploy-img \
  /usr/local/bin/heroku-deploy/

command=""

if [ $1 = "deploy" ]; then
  echo "--- Deploying $DEPLOYMENT_APP_NAME"
  command="git push heroku $BUILDKITE_COMMIT:master"
elif [ $1 = "db_migrate" ]; then
  echo "--- Running DB Migration"
  command="heroku run --exit-code 'rake db:migrate' -a $DEPLOYMENT_APP_NAME"
elif [ $1 = "custom" ]; then
  echo "--- Running custom command: '${@:2}'"
  command="${@:2}"
fi

# run it
docker run \
  -e DEPLOYMENT_APP_NAME \
  -e HEROKU_DEPLOYMENT_LOGIN \
  -e HEROKU_DEPLOYMENT_API_KEY \
  -e BUILDKITE_COMMIT \
  -v `pwd`:/home/panorama/app \
  -it heroku-deploy-img \
  $command
