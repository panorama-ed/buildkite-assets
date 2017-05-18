#! /bin/bash
set -e

# we need a .netrc file for the toolbelt to use
cat >> ~/.netrc <<NETRC
machine api.heroku.com
  login $HEROKU_DEPLOYMENT_LOGIN
  password $HEROKU_DEPLOYMENT_API_KEY
machine git.heroku.com
  login $HEROKU_DEPLOYMENT_LOGIN
  password $HEROKU_DEPLOYMENT_API_KEY
NETRC

chmod 600 ~/.netrc

# update heroku toolbelt to the latest version
# NOTE: This has to happen after the netrc has been written, otherwise
# this would happen in the Dockerfile at build time.
heroku

cd app/
heroku git:remote --app $DEPLOYMENT_APP_NAME

# run whatever commands come in
if [ -n "$1" ]; then
  bash -c "$*"
else
  echo "-- NO COMMAND PASSED IN --"
fi
