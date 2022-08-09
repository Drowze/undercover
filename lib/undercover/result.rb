# frozen_string_literal: true

require 'forwardable'

module Undercover
  class Result
    extend Forwardable

    attr_reader :node, :coverage, :file_path

    def_delegators :node, :first_line, :last_line, :name

    def initialize(node, file_cov, file_path)
      @node = node
      @coverage = file_cov.select do |ln, _|
        ln > first_line && ln < last_line
      end
      @file_path = file_path
      @flagged = false
    end

    def flag
      @flagged = true
    end

    def flagged?
      @flagged
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def uncovered?(line_no)
      # check branch coverage for line_no
      coverage.each do |ln, _block, _branch, cov|
        return true if ln == line_no && cov && cov.zero?
      end

      # check line coverage for line_no
      line_cov = coverage.select { |cov| cov.size == 2 }.find { |ln, _cov| ln == line_no }
      line_cov && line_cov[1].zero?
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    # Method `coverage_f` returns the total coverage of this Undercover::Result
    # as a % value, taking into account missing branches. Line coverage will be counted
    # as 0 if any branch is untested.
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def coverage_f
      lines = {}
      coverage.each do |ln, block_or_line_cov, _, branch_cov|
        lines[ln] = 1 unless lines.key?(ln)
        if branch_cov
          lines[ln] = 0 if branch_cov.zero?
        elsif block_or_line_cov.zero?
          lines[ln] = 0
        end
      end
      return 1.0 if lines.keys.size.zero?

      (lines.values.sum.to_f / lines.keys.size).round(4)
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # TODO: re-enable rubocops
    #
    # Zips coverage data (that doesn't include any non-code lines) with
    # full source for given code fragment (this includes non-code lines!)
    def lines_with_data # rubocop:disable Metrics/MethodLength
      cov_enum = coverage.each
      node.source_lines_with_numbers.map do |line_no, source|
        cov_line_no = begin
          cov_enum.peek[0]
        rescue StopIteration
          -1
        end
        {
          line_no: line_no,
          source: source,
          hits: cov_line_no == line_no ? cov_enum.next[1] : nil,
          branch_coverage: branch_coverage_for(line_no)
        }
      end
    end

    def branch_coverage_for(line_number)
      branches = coverage.select { |cov| cov.size == 4 && cov[0] == line_number }
      return if branches.size.zero?

      count_covered = branches.count { |cov| cov[3].positive? }
      {total_branches: branches.size, covered_branches: count_covered}
    end

    def file_path_with_lines
      "#{file_path}:#{first_line}:#{last_line}"
    end

    def inspect
      "#<Undercover::Report::Result:#{object_id}" \
        " name: #{node.name}, coverage: #{coverage_f}>"
    end
    alias to_s inspect
  end
end
