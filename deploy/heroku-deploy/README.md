__HELLO__ and welcome to the heroku deploy docker image!

This will build a docker image suitable to use for deployment to heroku from
buildkite.

You will need three environment variables to use this. Buildkite takes care of
this for us by pulling in a special env file we created, but here are the
variables in case you want to do some local development:

* __DEPLOYMENT_APP_NAME__: The name of the heroku app to deploy to
* __HEROKU_DEPLOYMENT_LOGIN__: The heroku login for a user capable of deploying
to the app above
* __HEROKU_DEPLOYMENT_API_KEY__: The API key for the user above.

To use this image, just build it and run your deploy commands.

## Build It :hammer:

```bash
docker build \
  --build-arg buildkite_agent_uid=$UID \
  -t heroku-deploy-img \
  deploy/heroku-deploy
```

## Run It :rocket:

```bash
docker run \
  -e DEPLOYMENT_APP_NAME=${HEROKU_APP_NAME_HERE} \
  -e HEROKU_DEPLOYMENT_LOGIN=${LOGIN_AS_DESCRIBED_ABOVE} \
  -e HEROKU_DEPLOYMENT_API_KEY=${KEY_AS_DESCRIBED_ABOVE} \
  -e BUILDKITE_COMMIT
  -e UID
  -v `pwd`:/home/panorama/app \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -it heroku-deploy-img
```

$UID and $BUILDKITE_COMMIT are populated by the system and buildkite,
respectively.

Any command you put at the end of this will be executed in the root directory of
the git repo this is run from.

Enjoy!
