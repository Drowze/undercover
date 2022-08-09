# frozen_string_literal: true

module Undercover
  class FormatterLoader
    autoload :PrettyFormatter, 'undercover/pretty_formatter'

    def self.default_formatter
      Undercover::PrettyFormatter
    end

    def initialize
      @enabled_formatters = Set.new
    end

    def enable!(formatter)
      @enabled_formatters << find_formatter(formatter)
    end

    def enabled_formatters
      return Set[self.class.default_formatter] if @enabled_formatters.empty?

      @enabled_formatters
    end

    private

    def find_formatter(formatter)
      case formatter
      when 'p', 'pretty'
        Undercover::PrettyFormatter
      else
        Object.const_get("Undercover::#{formatter}")
      end
    end
  end
end
