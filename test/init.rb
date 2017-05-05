# Read bootstrap script
bootstrap_script = File.read("../bootstrap.sh")

# Extract Ruby pre-hook script
pre_hook = bootstrap_script.split("check_command_whitelist.rb\n")[1]
pre_hook = pre_hook.split("RUBY\n")[0]

test_repo = "test-repo"

# Ensure some content in the test-repo
unless Dir.exist?(test_repo)
  Dir.mkdir(test_repo)

  File.write(
    "#{test_repo}/buildkite_command.sh",
    "echo Hello World!"
  )

  Dir.mkdir("#{test_repo}/buildkite")
  File.write(
    "#{test_repo}/buildkite/pipeline.yml",
    "steps:\n  - command: echo Hello World!"
  )
end

# Create the script
File.write("#{test_repo}/pre-hook.rb", pre_hook)

# Run test
fork { exec "./execute-test.sh" }
