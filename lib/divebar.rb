# require "divebar/version"

module Divebar
  Style = Struct.new(:tick_chars, :progress_chars, :template)
  module Styles
    Default = Style.new(
      "⠁⠁⠉⠙⠚⠒⠂⠂⠒⠲⠴⠤⠄⠄⠤⠠⠠⠤⠦⠖⠒⠐⠐⠒⠓⠋⠉⠈⠈ ".chars,
      "█░".chars,
      "%<bar>s %<pos>d/%<len>d %<msg>s"
    )

    Fancy = Style.new(
      "⠁⠁⠉⠙⠚⠒⠂⠂⠒⠲⠴⠤⠄⠄⠤⠠⠠⠤⠦⠖⠒⠐⠐⠒⠓⠋⠉⠈⠈ ".chars,
      "█▇▆▅▄▃▂▁  ".chars,
      " %<spinner>s %<bar>s %<pos>d/%<len>d %<msg>s"
    )
  end

  class Progress
  	def initialize(len: nil, width: 30, style: Styles::Fancy)
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
	  		@style.tick_chars[@tick % @style.tick_chars.size]
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
x = Divebar::Progress.new(len: 256)
0.upto(256) do |pos|
	x.pos = pos
	x.message = messages[pos] if messages.key?(pos)
	STDERR.puts "\033[A\33[2K\r#{x.render}"
	STDERR.flush
	sleep 0.10
end

