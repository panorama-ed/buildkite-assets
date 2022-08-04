#!/bin/bash

# This script checks that the image from the heroku-deploy Dockerfile can be
# built successfully. This check is done in the buildkite-assets repo to prevent
# an unbuildable Dockerfile from being deployed to buildkite instances.

DOCKER_IMAGE_NAME=check-heroku-deploy-image

echo "--- Running heroku-deploy build"
docker build \
  --build-arg buildkite_agent_uid=$UID \
  -t $DOCKER_IMAGE_NAME /usr/local/bin/heroku-deploy > build_results.out

EXIT_STATUS=$?

if [ $EXIT_STATUS -ne 0 ]; then
  echo "+++ Build Results"
else
  echo "--- Build Results"
fi
cat build_results.out

exit $EXIT_STATUS
