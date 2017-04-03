#!/bin/bash
set -eu

#############################################################################
# Write out a ruby script to ensure:
# 1) that buildkite only clones from a whitelisted set of Panorama repositories
# 2) that buildkite can only run commands that have been white listed from
#    within one of those repositories
#############################################################################
cat <<RUBY > /etc/buildkite-agent/check_command_whitelist.rb
require "yaml"

KNOWN_REPOSITORIES = [
  "git@bitbucket.org:panoramaed/rainbow-backend.git"
]

# This command allows us to upload and process the pipeline file from our
# repositories
DEFAULT_ALLOWED_COMMANDS = [
  "buildkite-agent pipeline upload ./buildkite/pipeline.yml"
]

unless KNOWN_REPOSITORIES.include?(ENV["BUILDKITE_REPO"])
  puts "The requested repository (#{ENV["BUILDKITE_REPO"]}) cannot be cloned " \
       "to this buildkite instance. If you actually need to use this repo " \
       "please add it to the allowed repositories inside of the agent " \
       "bootstrapping script."

  exit 4
end

pipeline_path = File.join(
  ENV["BUILDKITE_BUILD_CHECKOUT_PATH"],
  "buildkite",
  "pipeline.yml"
)

unless File.exists?(pipeline_path)
  puts "The repository needs to have a 'buildkite/pipeline.yml' file " \
       "that specifies the commands allowed to run on the buildkite server!"
  exit 1
end

pipeline = YAML.load(File.read(pipeline_path))
allowed_commands = pipeline["steps"].map { |step| step["command"] }.compact +
                   DEFAULT_ALLOWED_COMMANDS

if allowed_commands.include?(ENV["BUILDKITE_COMMAND"])
  puts "The given command is whitelisted and can be run"
  exit 0
else
  puts "The given command is not in the 'buildkite/pipeline.yml' file " \
       "and therefore will not be run. Please add it to the whitelist if it " \
       "should be allowed."
  exit 2
end
RUBY

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
# pretending to be bitbucket)
#############################################################################
cat <<EOF >> /etc/buildkite-agent/buildkite-agent.cfg
no-automatic-ssh-fingerprint-verification=true
EOF

#############################################################################
# Write out the bitbucket known SSH fingerprint so that we can clone from
# our repositories without getting asked for user entry.
#############################################################################
AGENT_HOME=`getent passwd buildkite-agent | cut -d: -f6`
mkdir -p $AGENT_HOME/.ssh
cat <<BITBUCKET_KNOWN_HOST > $AGENT_HOME/.ssh/known_hosts
bitbucket.org,104.192.143.1 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==
BITBUCKET_KNOWN_HOST
chown buildkite-agent: $AGENT_HOME/.ssh
chown buildkite-agent: $AGENT_HOME/.ssh/known_hosts
