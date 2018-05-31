FROM heroku/cedar:14

# Install Docker client, which is used by Heroky CLI for container release
# see installation instructions: https://docs.docker.com/install/linux/docker-ce/binaries/
ENV DOCKERVERSION=18.03.1-ce
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
  && mv docker-${DOCKERVERSION}.tgz docker.tgz \
  && tar xzvf docker.tgz \
  && mv docker/docker /usr/local/bin \
  && rm -r docker docker.tgz

# Install Heroku CLI, which uses Docker client for container release
# see installation instructions: https://devcenter.heroku.com/articles/heroku-cli#standalone-installation
RUN curl https://cli-assets.heroku.com/install-standalone.sh | sh

# Here, we take the UID for the user we will use in the docker image.
# We do this so that we can map it to the user that built the docker image,
# so file permissions will work inside the container.
#
# We pass it in as a buildarg so we can use the $UID environment variable
ARG buildkite_agent_uid
RUN useradd -u $buildkite_agent_uid -m panorama

# Make the platform API gem available to ruby scripts run inside the container.
# Useful for scripting things like environment variable updates
RUN gem install platform-api --no-rdoc --no-ri --version "2.1.0"

WORKDIR /home/panorama

ADD heroku_deploy.sh .
ENTRYPOINT ["./heroku_deploy.sh"]
