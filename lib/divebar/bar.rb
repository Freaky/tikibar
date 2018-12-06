# frozen_string_literal: true

module Divebar
  # A caching progress bar renderer.
  class Bar
    include Enumerable

    # The number of characters the bar takes up
    attr_reader :width

    # The list of characters representing how the bar is rendered
    attr_reader :chars

    # The number of discrete states the bar can be in
    attr_reader :steps

    alias size steps
    alias length steps
    alias count steps

    # Create a bar renderer taking up +width+ characters, rendering the bar
    # using a list of +chars+ characters that starts with a background
    # character, zero or more intermediate characters from low to high, followed
    # by the fill character.
    #
    # @param width [Integer] character width of the bar
    # @param chars [String, Array<String>] a list of characters
    # @return [Bar]
    def initialize(width: 30, chars: "-~+=#")
      chars = chars.chars if chars.is_a?(String)
      raise ArgumentError, "must specify at least two chars" if chars.size < 2

      @width = Integer(width)
      @chars = chars
      @bgchar = chars.first
      @fillchar = chars.last
      @steps = (chars.size - 2) * width
      @intermediates = chars[1..-2] if chars.size > 2
      @barcache = Array.new(@steps)
    end

    # Return the rendered progress bar for this step
    #
    # @param pos [Integer] the current render position, 0..size
    # @return [String] frozen representation of the bar
    def [](pos)
      @barcache[pos] ||= render_step(pos)
    end

    # Create a new instance of the bar with a new width.  Returns self if the
    # width has not changed.
    #
    # @param width [Integer] character width of the bar
    # @return [Bar]
    def with_width(width)
      return self if width == @width

      self.class.new(width: width, chars: @chars)
    end

    # Set a new width for the bar.  Not thread safe.
    #
    # @param width [Integer] character width of the bar
    # @return [Integer]
    def width=(width)
      Integer(width).tap do |w|
        @width = w
        @barcache.clear
      end
    end

    # Iterate over each state of the bar
    #
    # @yieldparam [String] bar a frozen String of the bar
    # @return [nil, Enumerator]
    def each
      return enum_for(__method__) unless block_given?

      0.upto(steps) do |i|
        yield self[i]
      end
    end

    private

    def render_step(pos)
      pct = pos / @steps.to_f
      fill = (width * pct).to_i
      bar = @fillchar * fill
      if @intermediates && fill < width
        bar << @intermediates.fetch(pos % @intermediates.size)
      end
      bar.ljust(width, @bgchar).freeze
    end
  end
end
