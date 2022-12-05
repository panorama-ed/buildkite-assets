#!/bin/bash

# This script checks that the image from the heroku-deploy Dockerfile can be
# built successfully. This check is done in the buildkite-assets repo to prevent
# an unbuildable Dockerfile from being deployed to buildkite instances.

echo "--- Building and testing with panorama_command.sh"
HEROKU_DEPLOY_PATH=deploy/heroku-deploy \
  HEROKU_DEPLOY_IMAGE_NAME=check-heroku-deploy-image \
  DEPLOYMENT_APP_NAME=panorama-addons \
  bash deploy/panorama_command.sh custom

exit $?
