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

# Run test
fork { exec "./execute-test.sh" }
