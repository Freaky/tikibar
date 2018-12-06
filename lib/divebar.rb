# require "divebar/version"

module Divebar
  Style = Struct.new(:name, :tick_chars, :progress_chars, :template)
  module Styles
    Default = Style.new(
      "default",
      "⠁⠁⠉⠙⠚⠒⠂⠂⠒⠲⠴⠤⠄⠄⠤⠠⠠⠤⠦⠖⠒⠐⠐⠒⠓⠋⠉⠈⠈ ".chars,
      "█░".chars,
      " %<bar>s %<spinner>s %<pos>d/%<len>d %<msg>s"
    )

    Plain = Style.new(
      "plain",
      ".:oO* ".chars,
      "#=+~-".chars,
      " %<bar>s %<spinner>s %<pos>d/%<len>d %<msg>s"
    )

    Fancy = Style.new(
      "fancy",
      "⠁⠁⠉⠙⠚⠒⠂⠂⠒⠲⠴⠤⠄⠄⠤⠠⠠⠤⠦⠖⠒⠐⠐⠒⠓⠋⠉⠈⠈ ".chars,
      "█▇▆▅▄▃▂▁  ".chars,
      " %<bar>s %<spinner>s %<pos>d/%<len>d %<msg>s"
    )

    Rough = Style.new(
      "rough",
      "⠁⠁⠉⠙⠚⠒⠂⠂⠒⠲⠴⠤⠄⠄⠤⠠⠠⠤⠦⠖⠒⠐⠐⠒⠓⠋⠉⠈⠈ ".chars,
      "█  ".chars,
      " %<bar>s %<spinner>s %<pos>d/%<len>d %<msg>s"
    )

    Fine = Style.new(
      "fine",
      "⠁⠁⠉⠙⠚⠒⠂⠂⠒⠲⠴⠤⠄⠄⠤⠠⠠⠤⠦⠖⠒⠐⠐⠒⠓⠋⠉⠈⠈ ".chars,
      "█▉▊▋▌▍▎▏  ".chars,
      " %<bar>s %<spinner>s %<pos>d/%<len>d %<msg>s"
    )

    Vertical = Style.new(
      "vertical",
      "⠁⠁⠉⠙⠚⠒⠂⠂⠒⠲⠴⠤⠄⠄⠤⠠⠠⠤⠦⠖⠒⠐⠐⠒⠓⠋⠉⠈⠈ ".chars,
      "█▇▆▅▄▃▂▁  ".chars,
      " %<bar>s %<spinner>s %<pos>d/%<len>d %<msg>s"
    )

    Fade = Style.new(
      "fade",
      "⠁⠁⠉⠙⠚⠒⠂⠂⠒⠲⠴⠤⠄⠄⠤⠠⠠⠤⠦⠖⠒⠐⠐⠒⠓⠋⠉⠈⠈ ".chars,
      "█▓▒░  ".chars,
      " %<bar>s %<spinner>s %<pos>d/%<len>d %<msg>s"
    )

    Block = Style.new(
      "block",
      "⠁⠁⠉⠙⠚⠒⠂⠂⠒⠲⠴⠤⠄⠄⠤⠠⠠⠤⠦⠖⠒⠐⠐⠒⠓⠋⠉⠈⠈ ".chars,
      "█▛▌▖  ".chars,
      " %<bar>s %<spinner>s %<pos>d/%<len>d %<msg>s"
    )
  end

  class Renderer
    def initialize(out = STDERR)
      @lines = []
      @out = out
      @last_written = 0
    end

    def <<(text)
      @buf << text
    end

    def flush
    end
  end

  class Progress
    attr_reader :style

    def initialize(len: nil, width: 30, style: Styles::Plain)
      @len = len
      @pos = 0
      @tick = 0
      @style = style
      @width = Integer(width)
      @renderproxy = Hash.new { |h,k| render_key(k) }
    end

    def pos=(pos)
      @pos = pos
    end

    def message=(msg)
      @msg = msg
    end

    alias msg= message=

    def finished?
      @pos == @len
    end

    def render
      @tick += 1
      format(@style.template, @renderproxy)
    end

    def render_key(k)
      case k
      when :msg then @msg.to_s
      when :spinner then render_spinner
      when :bar then render_bar
      when :pos then @pos
      when :len then @len
      end
    end

    def render_spinner
      if finished?
        @style.tick_chars.last
      else
        @style.tick_chars[@tick % (@style.tick_chars.size - 1)]
      end
    end

    def render_bar
      width = @width
      pct = fraction
      fill = pct * width
      bg = width - fill.to_i

      bar = @style.progress_chars[0] * fill.to_i

      if pct.nonzero? && bg.nonzero?
        n = (@style.progress_chars.length - 2).clamp(0, width)
        cur_char = if n.zero?
          1
        else
          (n - (fill * n.to_f).to_i % n)
        end
        bar << @style.progress_chars[cur_char]
        bg -= 1
      end

      bar << @style.progress_chars.last * bg
      bar
    end

    def fraction
      return 0.0 if @pos.zero?
      return 1.0 if @len.zero?
      (@pos / @len.to_f)
    end
  end

  class MultiProgress
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

bars = Divebar::Styles.constants.map do |c|
	Divebar::Progress.new(len: 256, style: Divebar::Styles.const_get(c))
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
    b.message = "(#{b.style.name}) #{messages[pos]}" if messages.key?(pos)
    buffer.puts "#{CURSOR_LEFTMOST}#{b.render}#{CLEAR_TO_EOL}"
  end
  STDERR.write(buffer.string)
  STDERR.flush
  buffer.truncate(0)
  buffer.rewind
  sleep(1 / 10.0)
end
