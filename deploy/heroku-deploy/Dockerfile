FROM heroku/cedar:14

RUN (mkdir -p /usr/local/lib && cd /usr/local/lib && curl https://cli-assets.heroku.com/branches/stable/heroku-linux-amd64.tar.gz -s -o - | tar xzf - --no-same-owner &&  /usr/local/lib/heroku/install)

# Here, we take the UID for the user we will use in the docker image.
# We do this so that we can map it to the user that built the docker image,
# so file permissions will work inside the container.
#
# We pass it in as a buildarg so we can use the $UID environment variable
ARG buildkite_agent_uid
RUN useradd -u $buildkite_agent_uid -m panorama
USER panorama
WORKDIR /home/panorama

ADD heroku_deploy.sh .
ENTRYPOINT ["./heroku_deploy.sh"]
