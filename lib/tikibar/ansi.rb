# frozen_string_literal: true

require "set"

module Tikibar
  # A simple ANSI library
  module Ansi
    COLOURS = {
      black: 0,
      red: 1,
      green: 2,
      yellow: 3,
      blue: 4,
      magenta: 5,
      cyan: 6,
      white: 7
    }.freeze

    ATTRIBUTES = {
      bold: 1,
      dim: 2,
      italic: 3,
      underlined: 4,
      blink: 5,
      reverse: 7,
      hidden: 8
    }.freeze

    COLOUR_ENABLED = ENV.fetch("CLICOLOR", "1") != "0" && STDOUT.tty? ||
                     ENV.fetch("CLICOLOR_FORCE", "0") != "0"

    Style = Struct.new(:bg, :fg, :attrs) do
      def format(str)
        return str unless COLOUR_ENABLED

        pfx = +""
        pfx << "\e[#{self.fg + 30}m" if self.fg
        pfx << "\e[#{self.bg + 40}m" if self.bg
        attrs.each do |at|
          pfx << "\e[#{at}m"
        end

        if pfx.empty?
          str
        else
          "#{pfx}#{str}\e[0m"
        end
      end
    end

    def self.from_dotted(fmt)
      Style.new(nil, nil, Set.new).tap do |style|
        fmt.split(".").each do |v|
          if v.start_with?("on_") && c = COLOURS[v[3..-1].to_sym]
            style.bg = c
          elsif c = COLOURS[v.to_sym]
            style.fg = c
          elsif a = ATTRIBUTES[v.to_sym]
            style.attrs << a
          else
            raise ArgumentError, "invalid format: #{v}"
          end
        end
      end
    end
  end
end

