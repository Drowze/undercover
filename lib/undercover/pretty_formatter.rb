# frozen_string_literal: true

module Undercover
  class PrettyFormatter
    def initialize(results)
      @results = results
    end

    def run
      puts self
    end

    def to_s
      return success unless @results.any?

      ([warnings_header] + formatted_warnings).join("\n")
    end

    private

    def formatted_warnings
      @results.map.with_index(1) do |res, idx|
        "🚨 #{idx}) node `#{res.node.name}` type: #{res.node.human_name},\n" +
          (' ' * pad_size) + "loc: #{res.file_path_with_lines}," \
                             " coverage: #{res.coverage_f * 100}%\n" +
          pretty_print(res)
      end
    end

    def pretty_print(result)
      pad = result.node.last_line.to_s.length
      result.lines_with_data.map do |line_data|
        line_no, line, hits, branch_coverage = line_data.values_at(:line_no, :source, :hits, :branch_coverage)
        [
          format_line(line_no, line, hits).rjust(pad),
          format_hits(hits),
          format_branch_coverage(branch_coverage),
        ].compact.join(' ')
      end.join("\n")
    end

    def format_line(line_no, line, hits)
      line_with_no = "#{line_no}: #{line}"

      if line.strip.length.zero? || hits.nil?
        Rainbow(line_with_no).darkgray.dark
      elsif hits.positive?
        Rainbow(line_with_no).green
      elsif hits.zero?
        Rainbow(line_with_no).red
      end
    end

    def format_hits(hits)
      return Rainbow('hits: n/a').italic.darkgray.dark if hits.nil?

      Rainbow("hits: #{hits}").italic.darkgray.dark
    end

    def format_branch_coverage(branch_coverage) # rubocop:disable Metrics/AbcSize
      return if branch_coverage.nil?

      branch_hits_text = "#{branch_coverage[:covered_branches]}/#{branch_coverage[:total_branches]}"
      Rainbow('branches: ').italic.darkgray.dark +
        if branch_coverage[:covered_branches] < branch_coverage[:total_branches]
          Rainbow(branch_hits_text).italic.red
        else
          Rainbow(branch_hits_text).italic.darkgray.dark
        end
    end

    def success
      "#{Rainbow('undercover').bold.green}: ✅ No coverage" \
        ' is missing in latest changes'
    end

    def warnings_header
      "#{Rainbow('undercover').bold.red}: " \
        '👮‍♂️ some methods have no test coverage! Please add specs for' \
        ' methods listed below'
    end

    def pad_size
      5 + (@results.size - 1).to_s.length
    end
  end
end
