#!/bin/bash
set -eu

## Make sure we'll use ruby 2.3
sudo yum install -y ruby23

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
if ! ruby2.3 /etc/buildkite-agent/check_command_whitelist.rb; then
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

BITBUCKET_SSH_KEY=AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==

for iprange in 18.205.93. 13.52.5.; do
	for suffix in {0..127}; do
		echo "bitbucket.org,$iprange$suffix ssh-rsa $BITBUCKET_SSH_KEY" > $AGENT_HOME/.ssh/known_hosts
	done
done

cat <<KNOWN_HOSTS > $AGENT_HOME/.ssh/known_hosts
# The GitHub public key is obtained by running `ssh -T git@github.com`,
# confirming that the fingerprint matches GitHub's published fingerprint
# (see: https://help.github.com/articles/github-s-ssh-key-fingerprints/),
# and then pulling the added line out of the local `known_hosts` file. We do
# not specify a given IP address for GitHub because GitHub uses many IP
# addresses and regularly changes them
# (see: https://help.github.com/articles/about-github-s-ip-addresses/).
github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
KNOWN_HOSTS

chown buildkite-agent: $AGENT_HOME/.ssh
chown buildkite-agent: $AGENT_HOME/.ssh/known_hosts
