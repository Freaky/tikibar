#!/usr/bin/env ruby

require "tikibar"
require "monotime"

colours = %w[red yellow green blue magenta green yellow].cycle
bold = Tikibar::Ansi.from_dotted("bold")

width = 20
steps = 512

m = Tikibar::Display.new

threads = Tikibar::Styles::Bars.constants.sort.map do |c|
  prefix = bold.format(c.to_s + ":").ljust(20)
  bar = Tikibar::Progress.new(
    len: steps,
    width: width,
    bar: Tikibar::Styles::Bars.const_get(c),
    spinner: Tikibar::Styles::Spinners::Cycle,
    template: "#{prefix}▕%<bar.#{colours.next}>s▏ %<spinner.red.dim>s %<pct.green.bold> 3d%% %<eta>6s"
  )

  Thread.new(m.add(bar)) do |tpb|
    mdelay = Monotime::Duration.millis(rand(10..30))

    0.upto(steps) do |step|
      tpb.pos = step
      mdelay.sleep
    end
  end
end

threads.each(&:join)
m.join
