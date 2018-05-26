require 'pty'
require 'English'
require 'rainbow/ext/string'
require 'commander'
require_relative '../minicron'
require Minicron::REQUIRE_PATH + 'constants'
require Minicron::REQUIRE_PATH + 'cli/commands'
require Minicron::REQUIRE_PATH + 'transport'
require Minicron::REQUIRE_PATH + 'monitor'
require Minicron::REQUIRE_PATH + 'transport/server'

include Commander::UI

module Minicron
  # Handles the main CLI interaction of minicron
  # TODO: this class is probably too complicated and should be refactored a bit
  module CLI
    # Function to the parse the config of the options passed to commands
    #
    # @param opts [Hash] The Commander provided options hash
    def self.parse_config(opts)
      # Parse the file config
      config = Minicron.parse_file_config(opts.config)

      # Parse the cli options
      Minicron.parse_config_hash(
        {
          'verbose' => opts.verbose,
          'debug' => opts.debug,
          'client' => {
            'dry_run' => opts.dry_run,
          },
          'server' => {
            'host' => opts.host,
            'port' => opts.port,
            'path' => opts.path,
            'pid_file' => opts.pid_file
          }
        },
        config
      )
    end

    # Sets up an instance of commander and runs it based on the argv param
    #
    # @param argv [Array] an array of arguments passed to the cli
    # @raise [ArgumentError] if no arguments are passed to the run cli command
    # i.e when the argv param is ['run']. A second option (the command to execute)
    # should be present in the array
    def self.run(argv)
      # replace ARGV with the contents of argv to aid testability
      ARGV.replace(argv)

      # Get an instance of commander
      @cli = Commander::Runner.new

      # Set some default otions on it
      setup

      # Add the server command to the cli
      Minicron::CLI::Commands.add_server_cli_command(@cli)

      # Add the db command to the cli
      Minicron::CLI::Commands.add_db_cli_command(@cli)

      # Add the config command to the cli
      Minicron::CLI::Commands.add_config_cli_command(@cli)

      # And off we go!
      @cli.run!
    end

    # Whether or not coloured output of the rainbox gem is enabled, this is
    # enabled by default
    #
    # @return [Boolean] whether rainbow is enabled or not
    def self.coloured_output?
      Rainbow.enabled
    end

    # Enable coloured terminal output from the rainbow gem, this is enabled
    # by default
    #
    # @return [Boolean] whether rainbow is enabled or not
    def self.enable_coloured_output!
      Rainbow.enabled = true
    end

    # Disable coloured terminal output from the rainbow gem, this is enabled
    # by default
    #
    # @return [Boolean] whether rainbow is enabled or not
    def self.disable_coloured_output!
      Rainbow.enabled = false
    end

    private

    # Sets the basic options for a commander cli instance
    def self.setup
      # ABT, always be tracing
      @cli.always_trace!

      # basic information for the help menu
      @cli.program :name, 'minicron'
      @cli.program :help, 'Author', 'James White <james.white@minicron.com>'
      @cli.program :help, 'License', 'GPL v3'
      @cli.program :version, Minicron::VERSION
      @cli.program :description, 'cli for minicron; a system a to manage and monitor cron jobs'

      # Display the output in a compact format
      @cli.program :help_formatter, Commander::HelpFormatter::TerminalCompact

      # Set the default command to run
      @cli.default_command :help

      # Add a global option for verbose mode
      @cli.global_option '--verbose', "Turn on verbose mode. Default: #{Minicron.config['verbose']}"

      # Add a global option for enabling debug mode
      @cli.global_option '--debug', "Turn on debug mode. Default: #{Minicron.config['debug']}"

      # Add a global option for passing the path to a config file
      @cli.global_option '--config FILE', "Set the config file to use. Default: #{Minicron::DEFAULT_CONFIG_FILE}"
    end
  end
end
