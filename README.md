# Buildkite
This repository contains the bootstraping code needed by our Buildkite setup.
**This repository is public and must not contain any secrets**.

The URL to the bootstrapping script is provided as a Cloudformation parameter
when the buildkite stack is created. Agents will then pull and execute the
script when they start.

# Bootstraping features

1. **SSH Fingerprint verification** By default, when Buildkite checks out a git
   repository it automatically accept any SSH fingerprint without verifying its
   authenticity. This leaves the agent vulnerable to man-in-the-middle-attacks
   in which another server could pretend to be bitbucket and provide the build
   agent with hostile code to execute. To prevent this the bootstrapping script
   disables automatic fingerprint verification and installs bitbucket's
   authentic fingerprint (pulled from their documentation). Since this is the
   only git provider we expect to access, there is no need to allow any other
   fingerprints.
2. **Repository Whitelisting** By default, Buildkite agents will pull from any
   repository that the Buildkite API instructs them to build. Our bootstrapping
   script restricts our agents to only pull a set of white listed repositories.
3. **Command Whitelisting** By default, Buildkite agents will run any command
   that the API instructs them to run. If the Buildkite API were compromised in
   some way, an attacker could therefore send malicious commands to our build
   agents. To avoid this, the bootstrapping script only allows commands that
   appear inside of the repository's ``buildkite/pipeline.yml`` file to be
   executed. Coupled with repository whitelisting, this makes it so that only
   commands committed to Panorama repos will be executed.

# Testing

## Pre-hook Ruby script

To test the changes in the pre-command hook ruby script that gets called before
each command in Buildkite (`check_command_whitelist.rb`), you can use the test
harness inside the `test` folder. There's an `init.rb` script that will simulate
a Buildkite run of the pre-command hook ruby script.

First step is to cd into `test` and run `ruby init.rb`. That will create a
`test-repo` subfolder with a sample pipeline file and a `buildkite_command.sh`
that simulates the command Buildkite would run.

If you have a Buildkite build that you want to test, you can find the command in
the `Environment` tab, searching for the `BUILDKITE_COMMAND` variable.

With everything setup, just cd into the `test` directory and run `ruby init.rb`.
Check the results, update `check_command_whitelist.rb` and try again.
