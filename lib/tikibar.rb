# frozen_string_literal: true

require "tikibar/version"
require "tikibar/bar"
require "tikibar/spinner"

module Tikibar
  Style = Struct.new(:name, :tick_chars, :progress_chars, :template)

  module Styles
    module Spinners
      Default = Spinner.new("\\|/-")
      Bubble  = Spinner.new(".oO*")
      Braille = Spinner.new("⠁⠁⠉⠙⠚⠒⠂⠂⠒⠲⠴⠤⠄⠄⠤⠠⠠⠤⠦⠖⠒⠐⠐⠒⠓⠋⠉⠈⠈")
    end

    module Bars
      Default  = Bar.new(chars: "-~+=#")
      Fill     = Bar.new(chars: "░█")
      Fine     = Bar.new(chars: "  ▏▎▍▌▋▊▉█")
      Rough    = Bar.new(chars: " █")
      Fade     = Bar.new(chars: " ░▒▓█")
      Vertical = Bar.new(chars: " ▁▂▃▄▅▆▇█")
      Block    = Bar.new(chars: " ▖▌▛█")
    end

    module Templates
      Default = " %<bar>s %<spinner>s %<pos>d/%<len>d %<msg>s"
    end
  end

  class Progress
    attr_reader :bar
    attr_reader :spinner
    attr_accessor :pos
    attr_accessor :message
    alias msg= message=

    def initialize(
      len: nil,
      width: 30,
      bar: Styles::Bars::Default,
      spinner: Styles::Spinners::Default,
      template: Styles::Templates::Default
    )
      @width = Integer(width)
      @len = len
      @pos = 0
      @tick = 0
      @bar = bar.with_width(width)
      @spinner = spinner
      @template = template
      @message = ""
      @renderproxy = Hash.new { |_, k| render_key(k) }
    end

    def finished?
      @pos == @len
    end

    def render
      @tick += 1
      format(@template, @renderproxy)
    end

    def render_key(key)
      case key
      when :msg then @message
      when :spinner then render_spinner
      when :bar then render_bar
      when :pos then @pos
      when :len then @len
      end
    end

    def render_spinner
      if finished?
        spinner.finish
      else
        spinner[@tick]
      end
    end

    def render_bar
      bar[(fraction * bar.steps).to_i]
    end

    def fraction
      return 0.0 if @pos.zero?
      return 1.0 if @len.zero?

      (@pos / @len.to_f)
    end
  end
end

messages = {
  0 => "Starting...",
  10 => "Still going",
  64 => "Frobrinating",
  128 => "Procrastinating...",
  200 => "Are we there yet?",
  256 => "Yay!"
}

bars = Tikibar::Styles::Bars.constants.map do |c|
  Tikibar::Progress.new(len: 256, bar: Tikibar::Styles::Bars.const_get(c))
end

CURSOR_UP = "\033[A"
CLEAR_LINE = "\33[2K"
CURSOR_LEFTMOST = "\r"
CLEAR_TO_EOL = "\33K"

buffer = StringIO.new

0.upto(256) do |pos|
  buffer.print(CURSOR_UP * bars.size) if pos.nonzero?
  bars.each do |b|
    b.pos = pos
    b.message = messages[pos] if messages.key?(pos)
    buffer.puts "#{CURSOR_LEFTMOST}#{b.render}#{CLEAR_TO_EOL}"
  end
  STDERR.write(buffer.string)
  STDERR.flush
  buffer.truncate(0)
  buffer.rewind
  sleep(1 / 10.0)
end
