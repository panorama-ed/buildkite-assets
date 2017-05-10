cd test-repo

export BUILDKITE_BUILD_CHECKOUT_PATH=`pwd`
export BUILDKITE_REPO=git@bitbucket.org:panoramaed/forklift.git
export BUILDKITE_COMMAND=$(<buildkite_command.sh)

echo "Checkout path: $BUILDKITE_BUILD_CHECKOUT_PATH"
echo "Buildkite repo: $BUILDKITE_REPO"
echo
echo "--- Buildkite COMMAND ---"
echo "$BUILDKITE_COMMAND"
echo "-------------------------"
echo
echo "--- Starting pre-hook script ---"
ruby ../../check_command_whitelist.rb
export EXIT_STATUS=$?
echo "--------------------------------"
echo

if [ $EXIT_STATUS -ne 0 ]; then
  echo "Pre hook checks **FAILED**"
else
  echo "Pre hook checks **PASSED**"
fi
