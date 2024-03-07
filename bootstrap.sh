#!/bin/bash
set -eu

KUBECTL_VERSION=v1.29.2
HELM_VERSION=v3.14.2
# Deploys could run on either `amd-small` or `arm-small` queues currently, so we need to install the correct version of the binaries
ARCH=$(uname -m)
if [[ $ARCH == "x86_64" ]]; then
  ARCH="amd64"
else
  ARCH="arm64"
fi

# Make sure we have Ruby 3 installed directly on the instance
# on AL2 need to use `amazon-linux-extras` to install `ruby3.0`
# AL2023 no longer has `amazon-linux-extras` so we use `dnf` to install ruby
OS_VERSION=$(uname -a)
if [[ $OS_VERSION =~ "amzn2023" ]]; then
  dnf install -y ruby
else
  amazon-linux-extras install -y ruby3.0
fi

## Install Terraform
curl "https://releases.hashicorp.com/terraform/1.5.4/terraform_1.5.4_linux_${ARCH}.zip" -o "terraform.zip"
sudo unzip ./terraform.zip -d /usr/local/bin

# Install Kubectl and Helm CLIs
wget -q https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/$ARCH/kubectl -O /usr/local/bin/kubectl
wget -q https://get.helm.sh/helm-$HELM_VERSION-linux-$ARCH.tar.gz -O - | tar -xzO linux-$ARCH/helm > /usr/local/bin/helm
chmod +x /usr/local/bin/helm /usr/local/bin/kubectl

## Clone buildkite-assets
git clone https://github.com/panorama-ed/buildkite-assets.git

## Go into the cloned repository directory
cd buildkite-assets

## Copy the script to be used in pre-command
cp check_command_whitelist.rb /etc/buildkite-agent

#############################################################################
# Extend the pre-command hook to run the safety script before running any
# commands on the buildkite instance. If the safety script fails, then
# the whole pipeline is aborted.
#############################################################################
cat <<EOF >> /etc/buildkite-agent/hooks/pre-command
if ! ruby /etc/buildkite-agent/check_command_whitelist.rb; then
  exit 1
fi
EOF

#############################################################################
# Extend the pre-exit hook to cleanup docker containers and images so that
# agents do not run out of disk space.
#############################################################################
cat <<EOF >> /etc/buildkite-agent/hooks/pre-exit
docker container prune -f
docker image prune -af
EOF

#############################################################################
# Require SSH fingerprint verification to prevent MITM attacks (e.g. someone
# pretending to be github)
#############################################################################
cat <<EOF >> /etc/buildkite-agent/buildkite-agent.cfg
no-automatic-ssh-fingerprint-verification=true
EOF

#############################################################################
# Write out the github known SSH fingerprint so that we can clone from
# our repositories without getting asked for user entry.
#############################################################################
AGENT_HOME=`getent passwd buildkite-agent | cut -d: -f6`
mkdir -p $AGENT_HOME/.ssh


cat <<KNOWN_HOSTS > $AGENT_HOME/.ssh/known_hosts
# The GitHub public key is obtained by running `ssh -T git@github.com`,
# confirming that the fingerprint matches GitHub's published fingerprint
# (see: https://help.github.com/articles/github-s-ssh-key-fingerprints/),
# and then pulling the added line out of the local `known_hosts` file. We do
# not specify a given IP address for GitHub because GitHub uses many IP
# addresses and regularly changes them
# (see: https://help.github.com/articles/about-github-s-ip-addresses/).
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
KNOWN_HOSTS

chown buildkite-agent: $AGENT_HOME/.ssh
chown buildkite-agent: $AGENT_HOME/.ssh/known_hosts
