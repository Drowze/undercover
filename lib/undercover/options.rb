# frozen_string_literal: true

require 'optparse'
require 'pathname'

module Undercover
  class Options
    attr_accessor :lcov, :path, :git_dir, :compare, :syntax_version

    def initialize
      @formatter_loader = Undercover::FormatterLoader.new
      # set defaults
      self.path = '.'
      self.git_dir = '.git'
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def parse(args)
      args = build_opts(args)

      OptionParser.new do |opts|
        opts.banner = 'Usage: undercover [options]'

        opts.on_tail('-h', '--help', 'Prints this help') do
          puts(opts)
          exit
        end

        opts.on_tail('--version', 'Show version') do
          puts VERSION
          exit
        end

        require_option(opts)
        formatter_option(opts)
        lcov_path_option(opts)
        project_path_option(opts)
        git_dir_option(opts)
        compare_option(opts)
        ruby_syntax_option(opts)
        # TODO: parse dem other options and assign to self
        # --quiet (skip progress bar)
        # --exit-status (do not print report, just exit)
      end.parse(args)

      guess_lcov_path unless lcov
      self
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    def formatters
      @formatter_loader.enabled_formatters
    end

    private

    def build_opts(args)
      project_options.concat(args)
    end

    def project_options
      args_from_options_file(project_options_file)
    end

    def args_from_options_file(path)
      return [] unless File.exist?(path)

      File.read(path).split('\n').flat_map(&:split)
    end

    def project_options_file
      './.undercover'
    end

    def require_option(parser)
      parser.on('--require FILE', 'Require Ruby file') do |file|
        require file
      end
    end

    def formatter_option(parser)
      parser.on('-f', '--formatter formatter', 'Formatter to output results') do |formatter|
        @formatter_loader.enable!(formatter)
      end
    end

    def lcov_path_option(parser)
      parser.on('-l', '--lcov path', 'LCOV report file path') do |path|
        self.lcov = path
      end
    end

    def project_path_option(parser)
      parser.on('-p', '--path path', 'Project directory') do |path|
        self.path = path
      end
    end

    def git_dir_option(parser)
      desc = 'Override `.git` with a custom directory'
      parser.on('-g', '--git-dir dir', desc) do |dir|
        self.git_dir = dir
      end
    end

    def compare_option(parser)
      desc = 'Generate coverage warnings for all changes after `ref`'
      parser.on('-c', '--compare ref', desc) do |ref|
        self.compare = ref
      end
    end

    def ruby_syntax_option(parser)
      versions = Imagen::AVAILABLE_RUBY_VERSIONS.sort.join(', ')
      desc = "Ruby syntax version, one of: #{versions}"
      parser.on('-r', '--ruby-syntax ver', desc) do |version|
        self.syntax_version = version.strip
      end
    end

    def guess_lcov_path
      cwd = Pathname.new(File.expand_path(path))
      self.lcov = File.join(cwd, 'coverage', 'lcov', "#{cwd.split.last}.lcov")
    end
  end
end
