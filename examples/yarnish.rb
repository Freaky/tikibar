#!/usr/bin/env ruby

require "tikibar"
require "monotime"

include Monotime

CURSOR_UP = "\033[A"
CLEAR_LINE = "\33[2K"
CURSOR_LEFTMOST = "\r"
CLEAR_TO_EOL = "\33[K"

PACKAGES = [
  "fs-events",
  "my-awesome-module",
  "emoji-speaker",
  "wrap-ansi",
  "stream-browserify",
  "acorn-dynamic-import",
]

COMMANDS = [
  "cmake .",
  "make",
  "make clean",
  "gcc foo.c -o foo",
  "gcc bar.c -o bar",
  "./helper.sh rebuild-cache",
  "make all-clean",
  "make test",
]

emoji = Tikibar::Ansi.from_dotted("cyan.dim")
LOOKING_GLASS = emoji.format("🔍 ")
TRUCK         = emoji.format("🚚 ")
CLIP          = emoji.format("🔗 ")
PAPER         = emoji.format("📃 ")
SPARKLE       = emoji.format("✨ ")

out = Tikibar::Display.new

start = Instant.now
out.puts "[1/4] #{LOOKING_GLASS}Resolving packages..."
out.puts "[2/4] #{TRUCK}Fetching packages..."
out.puts "[3/4] #{CLIP}Linking dependencies..."

deps = 1232
delay = Duration.millis(3)
pb = out.add(Tikibar::Progress.new(len: deps, bar: Tikibar::Styles::Bars::Fill, width: IO.console.winsize.last - 10))
0.upto(deps) do |i|
  pb.pos = i
  delay.sleep
end
pb.clear
out.puts "[4/4] #{PAPER}Building fresh packages..."

workers = 4.times.map do |i|
  count = rand(30..80)
  pb = out.add(Tikibar::Progress.new(len: count, spinner: Tikibar::Styles::Spinners::Cycle, template: "[#{i + 1}/?] %<spinner.red>s %<msg.dim>s"))

  Thread.new(pb) do |tpb|
    pkg = PACKAGES[rand(PACKAGES.size - 1)]

    count.times do |ii|
      cmd = COMMANDS[rand(COMMANDS.size - 1)]

      tpb.message = "#{pkg}: #{cmd}"
      tpb.pos = ii + 1

      Duration.millis(rand(25..200)).sleep
    end

    tpb.finish "waiting..."
  end
end

workers.each(&:join)
out.puts "#{SPARKLE} Done in #{start.elapsed.to_s(0)}"
out.finish_and_clear

