# frozen_string_literal: true

require "tikibar/ansi"

module Tikibar
  # A simple ANSI colourizer
  class Template
    # The stringified template
    attr_reader :template

    def initialize(template)
      @template = template.freeze
      @preprocessed = preprocess(template).freeze
    end

    def render(vars)
      format(@preprocessed, vars)
    end

    private

    Fields = /[bBdiouxXeEfgGaAcps]/
    Flags = /[ #+*-]?/
    Width = /(?:\.?\d)?/

    FormatPattern = /%<([^.]+)\.([^>]+)>(#{Flags}#{Width}#{Fields})/
    ReplacePattern = /%\{([^.]+)\.([^}]+)}/

    def preprocess(t)
      t.split("%%", -1)
       .map { |unescaped| reformat(unescaped) }
       .join("%%")
    end

    def reformat(t)
      t.gsub(FormatPattern) do |fmt|
        key, modifiers, rest = $1, $2, $3
        Ansi.from_dotted(modifiers).format("%<#{key}>#{rest}")
      end.gsub(ReplacePattern) do |fmt|
        key, modifiers = $1, $2
        Ansi.from_dotted(modifiers).format("%{#{key}}")
      end
    end
  end
end
