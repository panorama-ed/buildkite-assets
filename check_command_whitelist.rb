# frozen_string_literal: true

###############################################################################
# The purpose of this script is to ensure that:
# 1) buildkite only clones from repositories coming from panoramaed org
# 2) buildkite can only run commands that have been white listed from within one
#    of those repositories
###############################################################################

require "yaml"

KNOWN_REPOSITORY_PREFIXES = [
  "git@github.com:panorama-ed/",
  "https://github.com/panorama-ed/"
].freeze

# This command allows us to upload and process the pipeline file from our
# repositories
DEFAULT_ALLOWED_COMMANDS = [
  "buildkite-agent pipeline upload ./buildkite/pipeline.yml"
].freeze

unless KNOWN_REPOSITORY_PREFIXES.any? do |prefix|
  ENV["BUILDKITE_REPO"].start_with?(prefix)
end
  puts "The requested repository (#{ENV['BUILDKITE_REPO']}) cannot be cloned " \
       "to this buildkite instance. If you actually need to use this repo " \
       "please modify the agent bootstrapping script to allow cloning it. "

  exit 4
end

pipeline_path = File.join(
  ENV["BUILDKITE_BUILD_CHECKOUT_PATH"],
  "buildkite",
  "pipeline.yml"
)

unless File.exist?(pipeline_path)
  puts "The repository needs to have a 'buildkite/pipeline.yml' file " \
       "that specifies the commands allowed to run on the buildkite server!"
  exit 1
end

yaml_content = File.read(pipeline_path)
begin
  pipeline = YAML.safe_load(yaml_content)
  allowed_commands = pipeline["steps"].
                     map { |step| step["command"] }.
                     flatten.
                     compact.
                     uniq + DEFAULT_ALLOWED_COMMANDS

  ENV["BUILDKITE_COMMAND"].split("\n").each do |command|
    next if allowed_commands.include?(command)

    puts "The given command is not in the 'buildkite/pipeline.yml' file " \
         "and therefore will not be run. Please add it to the whitelist if it " \
         "should be allowed."
    exit 2
  end

  exit 0
rescue Psych::SyntaxError => e
  puts "Failed to parse #{pipeline_path}"
  puts "Error message: #{e.message}"
  puts "You have an error on line #{e.line}, this is your file:"
  yaml_content.
    split("\n").
    each_with_index.
    each do |line, line_number|
      puts "#{line_number + 1}: #{line}"
    end
  exit 3
end
