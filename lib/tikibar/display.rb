# frozen_string_literal: true

require "thread"
require "io/console"

module Tikibar
  class Display
    include Monotime

    attr_reader :output
    attr_accessor :refresh

    class SyncProxy < BasicObject
      attr_reader :obj

      def initialize(obj)
        @obj = obj
        @mutex = ::Mutex.new
      end

      def synchronize
        @mutex.synchronize do
          yield(@obj)
        end
      end

      def inspect
        "#<SyncProxy: #{@obj.inspect}>"
      end

      def method_missing(meth, *args, &block)
        synchronize do
          @obj.__send__(meth, *args, &block)
        end
      end
    end

    CURSOR_LEFTMOST = "\r"
    CURSOR_UP       = "\e[A"
    CLEAR_LINE      = "\e[2K"
    CLEAR_TO_EOL    = "\e[K"

    def initialize(
      refresh: Duration.millis(1000 / 15.0),
      output: STDOUT
    )
      refresh = Duration.millis(refresh) unless refresh.is_a?(Duration)

      @output = output
      @bars = SyncProxy.new([])
      @puts = SyncProxy.new([])
      @refresh = refresh
      @rendered_lines = 0
      @running = true
      spawn
    end

    def puts(*msg)
      @puts.push(*msg)
    end

    def add(bar)
      proxy = SyncProxy.new(bar)
      @bars << proxy
      proxy
    end

    def remove(bar)
      if bar.is_a?(SyncProxy)
        @bars.delete(bar)
      else
        @bars.delete_if { |b| b.obj == bar }
      end
    end

    def join
      @running = false
      @render_thread.join
    end

    alias finish join

    def finish_and_clear
      @bars.clear
      join
    end

    private

    def spawn
      @render_thread = Thread.new do
        refresh.sleep while render_iter
      end
    end

    def render_iter
      # Reset the cursor to our starting point
      output.print(CURSOR_UP * @rendered_lines) if @rendered_lines.nonzero?

      # Print any buffered messages
      @puts.synchronize do |lines|
        unless lines.empty?
          lines.each do |l|
            output.print CLEAR_TO_EOL
            output.puts l
          end
          lines.clear
        end
      end

      # Print visible bars
      next_lines = @bars.select(&:visible?)
      next_lines.each do |bar|
        output.print("#{CURSOR_LEFTMOST}#{bar.render}#{CLEAR_TO_EOL}\n")
      end

      # Clear any remaining lines
      orphan_lines = @rendered_lines - next_lines.size

      if orphan_lines.positive?
        output.print("#{CLEAR_TO_EOL}\n" * orphan_lines)
        output.print(CURSOR_UP * orphan_lines)
      end

      @rendered_lines = next_lines.count
      @running
    end
  end
end
