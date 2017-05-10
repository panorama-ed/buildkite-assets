#!/bin/sh

set -o pipefail
set -e

command=""

if [ -z "$1" ]; then
  echo "Please pass in a command, it can be one of the following:"
  echo
  echo " deploy              Deploys $DEPLOYMENT_APP_NAME"
  echo " db_migrate          Run DB migration for $DEPLOYMENT_APP_NAME"
  echo " custom {commands}   Runs a custom command that is passed in"
  echo
  exit 1
elif [ $1 = "deploy" ]; then
  command="git push heroku $BUILDKITE_COMMIT:master"
elif [ $1 = "db_migrate" ]; then
  command="heroku run --exit-code 'rake db:migrate' -a $DEPLOYMENT_APP_NAME"
elif [ $1 = "custom" ]; then
  command="${@:2}"
fi

# build it
docker build \
  --build-arg buildkite_agent_uid=$UID \
  -t heroku-deploy-img \
  /usr/local/bin/heroku-deploy/

echo "Running command: $command"

# run it
docker run \
  -e DEPLOYMENT_APP_NAME \
  -e HEROKU_DEPLOYMENT_LOGIN \
  -e HEROKU_DEPLOYMENT_API_KEY \
  -e BUILDKITE_COMMIT \
  -v `pwd`:/home/panorama/app \
  -it heroku-deploy-img
  $command
