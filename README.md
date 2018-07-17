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
   in which another server could pretend to be github and provide the build
   agent with hostile code to execute. To prevent this the bootstrapping script
   disables automatic fingerprint verification and installs github's
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

## Pre-command hook Ruby script

If you change the `check_command_whitelist.rb` file, you can test that your
changes worked by running the test suite locally. To do that just call the
script `buildkite/run_check_command_whitelist_tests.sh`, like the following:

```bash
$ ./buildkite/run_check_command_whitelist_tests.sh
```
