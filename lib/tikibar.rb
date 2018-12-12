# frozen_string_literal: true

# stdlib
require "thread"
require "io/console"

# gems
require "monotime"

# local
require "tikibar/bar"
require "tikibar/display"
require "tikibar/eta"
require "tikibar/spinner"
require "tikibar/template"
require "tikibar/version"

module Tikibar
  module Styles
    module Spinners
      Default = Spinner.new("\\|/-")
      Bubble  = Spinner.new(".oO*")
      Braille = Spinner.new("⠁⠁⠉⠙⠚⠒⠂⠂⠒⠲⠴⠤⠄⠄⠤⠠⠠⠤⠦⠖⠒⠐⠐⠒⠓⠋⠉⠈⠈")
      Cycle   = Spinner.new("⠁⠂⠄⡀⢀⠠⠐⠈")
      Twirl   = Spinner.new(["-", "\\", "|", "/", "-", " -", " /", " |", " \\", " -"])
      Bounce  = Spinner.new(["-    ", " -   ", "  -  ", "   - ", "    -"], reverse: true)
    end

    module Bars
      Default  = Bar.new(chars: "-~+=#")
      Simple   = Bar.new(chars: " =")
      Box      = Bar.new(chars: " ╡═")
      Line     = Bar.new(chars: " ┤─")
      Fill     = Bar.new(chars: "░█")
      Fine     = Bar.new(chars: "   ▏▎▍▌▋▊▉█")
      Rough    = Bar.new(chars: " █")
      Fade     = Bar.new(chars: "  ░▒▓█")
      Vertical = Bar.new(chars: "  ▁▂▃▄▅▆▇█")
      Block    = Bar.new(chars: "  ▖▌▛█")
      Braille6 = Bar.new(chars: " ⠄⠆⠇⠗⠷⠿")
      Braille8 = Bar.new(chars: " ⡀⡄⡆⡇⡗⡷⣷⣿")
    end

    module Templates
      Default = Template.new("%<bar.cyan>s %<pos>d/%<len>d")
      Full    = Template.new("%<bar>s %<spinner>s %<pos>d/%<len>d %<eta>s %<msg>s")
      Spinner = Template.new("%<spinner>s %<msg>s")
      Coloured = Template.new("%<bar.cyan.dim>s %<pos>d/%<len>d")
    end
  end

  class Progress
    include Monotime

    ETA_CUTOFF = Duration.secs(1)

    attr_reader :bar
    attr_reader :spinner
    attr_accessor :prefix
    attr_accessor :pos
    attr_accessor :len
    attr_accessor :message
    attr_accessor :hidden
    attr_reader :start
    alias msg= message=

    def initialize(
      len: nil,
      width: 30,
      bar: Styles::Bars::Default,
      spinner: Styles::Spinners::Default,
      template: Styles::Templates::Default,
      prefix: "",
      message: "",
      hidden: false
    )
      template = Template.new(template) if template.is_a?(String)

      @width = Integer(width)
      @len = len
      @pos = 0
      @lastpos = 0
      @tick = 0
      @bar = bar.with_width(@width)
      @spinner = spinner
      @template = template
      @message = message
      @prefix = prefix
      @hidden = hidden
      vars = {
        prefix: -> { @prefix },
        msg: -> { @message },
        spinner: -> { render_spinner },
        bar: -> { render_bar },
        eta: -> { render_eta },
        pos: -> { @pos },
        len: -> { @len },
        pct: -> { fraction * 100 }
      }.freeze
      @renderproxy = Hash.new { |_, key| vars.fetch(key).call }
      @start = Instant.now
      @eta = Eta.new
    end

    def finished?
      @pos == @len
    end

    def visible?
      !@hidden
    end

    def hidden?
      !!@hidden
    end

    def render
      @eta.step(Instant.now, @pos) if @pos != @lastpos
      @tick += 1
      @template.render(@renderproxy)
    end

    def finish(message = nil)
      @finished = true
      @message = message.to_s
      @pos = @len
    end

    def clear
      @hidden = true
      finish
    end

    private

    def render_key(key)
      @renderkeys.fetch(key).call
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

    def render_eta
      return "" if finished?

      est = (@eta.time_per_step * (@len - @pos))
      if est > ETA_CUTOFF
        est.to_s(0)
      else
        ""
      end
    end

    def fraction
      return 0.0 if @pos.zero?
      return 1.0 if @len.zero?

      (@pos / @len.to_f)
    end
  end

  def self.spinner(spinner = :Default)
    spin = case spinner
    when Spinner then spinner
    when Symbol then Styles::Spinners.const_get(spinner)
    when String then Spinner.new(spinner)
    else raise ArgumentError, "Unhandled spinner: #{spinner.inspect}"
    end
    Progress.new(template: Styles::Templates::Spinner, spinner: spin)
  end

  def self.bar(bar = :Default, width: 30)
    b = case bar
    when Bar then bar
    when Symbol then Styles::Bars.const_get(bar)
    when String, Array then Bar.new(bar)
    else raise ArgumentError, "Unahdneld bar: #{bar.inspect}"
    end

    Progress.new(bar: b, width: width)
  end
end
