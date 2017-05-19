require "fileutils"
require "open3"
require "rspec"

RSpec.describe "Pre-command Hook" do

  PROJECT_ROOT = Pathname.new("#{File.dirname(__FILE__)}/..").cleanpath
  SCRIPT_UNDER_TEST = "#{PROJECT_ROOT}/check_command_whitelist.rb"

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
        "ruby #{SCRIPT_UNDER_TEST}"
      )
      exit_status = status.exitstatus
    end

    [exit_status, output, err]
  end

  subject do
    status, output, err = execute_script(buildkite_command)
    output = err if !err.nil? && !err.empty?
    {
      status: status,
      output: output
    }
  end

  let(:repo) { "git@bitbucket.org:panoramaed/forklift.git" }
  let(:repo_path) { Dir.mktmpdir }
  let(:command) { "echo Hello World!" }
  let(:buildkite_command) { command }

  context "when there's no pipeline.yml" do
    it "fails with message explaining why" do
      expect(subject[:status]).to eq(1), "Expected script to fail"
      expect(subject[:output]).
        to include("needs to have a 'buildkite/pipeline.yml'")
    end
  end

  context "when there's a pipeline.yml" do
    let!(:pipeline_file) do
      FileUtils.mkdir_p("#{repo_path}/buildkite")
      File.open("#{repo_path}/buildkite/pipeline.yml", "w+") do |file|
        file.write(pipeline_content)
      end
      "#{repo_path}/buildkite/pipeline.yml"
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
        let(:repo) { "git@bitbucket.org:somehwere_malicious/rainbow.git" }

        it "fails with a reasonable message" do
          expect(subject[:status]).to eq(4), "Expected script to fail"
          expect(subject[:output]).to include(
            "The requested repository (#{repo}) cannot be cloned"
          )
        end
      end

      context "but the command is not in pipeline.yml" do
        let(:buildkite_command) { "echo Good Bye World!" }

        it "fails with a reasonable message" do
          expect(subject[:status]).to eq(2), "Expected script to fail"
          expect(subject[:output]).to include(
            "command is not in the 'buildkite/pipeline.yml'"
          )
        end
      end

      context "and there are multiple commands from Buildkite" do
        let(:command_1) { "echo Good Bye World!" }
        let(:buildkite_command) { "#{command}\n#{command_1}" }

        it "fails if one command is not in the yaml file" do
          expect(subject[:status]).to eq(2), "Expected script to fail"
          expect(subject[:output]).to include(
            "command is not in the 'buildkite/pipeline.yml'"
          )
        end

        context "and all are allowed" do
          let(:command_1) do
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
      let(:command_1) { "echo Good Bye World!" }
      let(:pipeline_content) do
        <<~YAML
          steps:
            - command:
              - #{command}
              - #{command_1}
        YAML
      end

      it "passes with all commands in the pipeline.yml" do
        [command, command_1].each do |cmd|
          status, output = execute_script(cmd)
          expect(status).to(
            eq(0),
            "Command was: '#{cmd}'\nOutput was: \n#{output}"
          )
        end
      end

      context "and Buildkite sends multiple commands" do
        let(:buildkite_command) { "#{command}\n#{command_1}" }

        it "passes when all are in the yaml" do
          expect(subject[:status]).to(
            eq(0),
            "Output was: \n#{output}"
          )
        end

        context "but one is not in the yaml" do
          let(:command_2) { "echo Something else" }
          let(:buildkite_command) { "#{command}\n#{command_2}" }

          it "fails with reasonable message" do
            expect(subject[:status]).to eq(2), "Expected script to fail"
            expect(subject[:output]).to include(
              "command is not in the 'buildkite/pipeline.yml'"
            )
          end
        end
      end
    end

    context "but yaml is malformed" do
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
end
