#!/bin/bash

DOCKER_IMAGE_NAME=check-command-whitelist

echo "--- Running Tests"
docker build -t $DOCKER_IMAGE_NAME .

docker run -it $DOCKER_IMAGE_NAME rspec > test.out

EXIT_STATUS=$?

if [ $EXIT_STATUS -ne 0 ]; then
  echo "+++ Test Results"
else
  echo "--- Test Results"
fi
cat test.out

exit $EXIT_STATUS
