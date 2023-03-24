#!/bin/bash
set -eu

## Make sure we have Ruby 3 installed directly on the instance
amazon-linux-extras install -y ruby3.0

## Install Terraform
curl "https://releases.hashicorp.com/terraform/1.2.7/terraform_1.2.7_linux_amd64.zip" -o "terraform.zip"
sudo unzip ./terraform.zip -d /usr/local/bin

## Clone buildkite-assets
git clone https://github.com/panorama-ed/buildkite-assets.git

## Go into the cloned repository directory
cd buildkite-assets

## Copy the script to be used in pre-command
cp check_command_whitelist.rb /etc/buildkite-agent

## Copy deploy scripts
cp -R deploy/* /usr/local/bin

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
