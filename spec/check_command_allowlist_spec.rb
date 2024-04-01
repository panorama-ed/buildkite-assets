# frozen_string_literal: true

require "fileutils"
require "open3"
require "rspec"
require "tempfile"
require "pathname"

RSpec.describe "Pre-command Hook" do # rubocop:disable RSpec/DescribeClass
  def execute_script(buildkite_command)
    environment = {
      "BUILDKITE_BUILD_CHECKOUT_PATH" => repo_path,
      "BUILDKITE_REPO" => repo,
      "BUILDKITE_COMMAND" => buildkite_command
    }

    output = ""
    err = ""
    exit_status = -1

    Dir.chdir(repo_path) do
      output, err, status = Open3.capture3(
        environment,
        "ruby #{script_under_test}"
      )
      exit_status = status.exitstatus
    end

    [exit_status, output, err]
  end

  def setup_pipeline_file(path, content)
    FileUtils.mkdir_p(path)
    File.write("#{path}/pipeline.yml", content)
  end

  subject do
    status, output, err = execute_script(buildkite_command)
    output = err if !err.nil? && !err.empty?
    {
      status: status,
      output: output
    }
  end

  let(:repo) { "git@github.com:panorama-ed/forklift.git" }
  let(:repo_path) { Dir.mktmpdir }
  let(:command) { "echo Hello World!" }
  let(:buildkite_command) { command }
  let(:project_root) { Pathname.new("#{File.dirname(__FILE__)}/..").cleanpath }
  let(:script_under_test) { "#{project_root}/check_command_allowlist.rb" }

  context "when there's no pipeline.yml" do
    it "fails with message explaining why" do
      expect(subject[:status]).to eq(1), "Expected script to fail"
      expect(subject[:output]).
        to include(
          "All projects in the repository must have a 'buildkite/pipeline.yml'"
        )
    end
  end

  context "when there's a pipeline.yml" do
    let!(:pipeline_file) do
      setup_pipeline_file("#{repo_path}/buildkite", pipeline_content)
    end

    context "with one command in it" do
      let(:pipeline_content) do
        <<~YAML
          steps:
            - command: #{command}
        YAML
      end

      it "passes if command is in the pipeline.yml" do
        expect(subject[:status]).to eq(0), "Output was: \n#{subject[:output]}"
      end

      context "when the repository is not allowed" do
        let(:repo) { "git@github.com:somehwere_malicious/rainbow.git" }

        it "fails with a reasonable message" do
          expect(subject[:status]).to eq(4), "Expected script to fail"
          expect(subject[:output]).to include(
            "The requested repository (#{repo}) cannot be cloned"
          )
        end
      end

      context "when the command is not in pipeline.yml" do
        let(:buildkite_command) { "echo Good Bye World!" }

        it "fails with a reasonable message" do
          expect(subject[:status]).to eq(2), "Expected script to fail"
          expect(subject[:output]).to include(
            "command is not in any of the 'buildkite/pipeline.yml' files"
          )
        end
      end

      context "when there are multiple commands from Buildkite" do
        let(:command1) { "echo Good Bye World!" }
        let(:buildkite_command) { "#{command}\n#{command1}" }

        it "fails if one command is not in the yaml file" do
          expect(subject[:status]).to eq(2), "Expected script to fail"
          expect(subject[:output]).to include(
            "command is not in any of the 'buildkite/pipeline.yml' files"
          )
        end

        context "when all are allowed" do
          let(:command1) do
            "buildkite-agent pipeline upload ./buildkite/pipeline.yml"
          end

          it "passes all checks" do
            expect(subject[:status]).
              to eq(0), "Output was: \n#{subject[:output]}"
          end
        end
      end
    end

    context "with multiple commands in it" do
      let(:command1) { "echo Good Bye World!" }
      let(:pipeline_content) do
        <<~YAML
          steps:
            - command:
              - #{command}
              - #{command1}
        YAML
      end

      it "passes with all commands in the pipeline.yml" do
        [command, command1].each do |cmd|
          status, output = execute_script(cmd)
          expect(status).to(
            eq(0),
            "Command was: '#{cmd}'\nOutput was: \n#{output}"
          )
        end
      end

      context "when Buildkite sends multiple commands" do
        let(:buildkite_command) { "#{command}\n#{command1}" }

        it "passes when all are in the yaml" do
          expect(subject[:status]).to(
            eq(0),
            "Output was: \n#{output}"
          )
        end

        context "when one is not in the yaml" do
          let(:command2) { "echo Something else" }
          let(:buildkite_command) { "#{command}\n#{command2}" }

          it "fails with reasonable message" do
            expect(subject[:status]).to eq(2), "Expected script to fail"
            expect(subject[:output]).to include(
              "command is not in any of the 'buildkite/pipeline.yml' files"
            )
          end
        end
      end
    end

    context "when yaml is malformed" do
      let(:pipeline_content) do
        <<~YAML
          steps:
            - label: This looks right
            command: #{command}
        YAML
      end

      it "fails with a reasonable message" do
        expect(subject[:status]).to(
          eq(3),
          "Expected script to fail, Output:\n#{subject[:output]}"
        )

        expect(subject[:output]).to include("Failed to parse")
      end
    end
  end

  context "when there are multiple pipeline files" do
    let!(:root_pipeline_file) do
      setup_pipeline_file("#{repo_path}/buildkite", root_pipeline_content)
    end

    let!(:subdir_pipeline_file) do
      setup_pipeline_file("#{repo_path}/some_subdir/buildkite",
                          subdir_pipeline_content)
    end

    let(:root_pipeline_content) do
      <<~YAML
        steps:
          - command: #{root_command}
      YAML
    end

    let(:subdir_pipeline_content) do
      <<~YAML
        steps:
          - command: #{subdir_command}
      YAML
    end

    let(:root_command) { "echo root command" }
    let(:subdir_command) { "echo subdir command" }

    it "passes for commands in any pipeline.yml" do
      [root_command, subdir_command].each do |cmd|
        status, output, _err = execute_script(cmd)
        expect(status).to eq(0),
                          "Command was: '#{cmd}'\nOutput was: \n#{output}"
      end
    end
  end
end
