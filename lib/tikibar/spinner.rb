# frozen_string_literal: true

module Tikibar
  # A cycling progress spinner indicator
  #
  # @example
  #   Spinner.new("1234").cycle { |spin| print("\r#{spin}") } # 1\r2\r3\r4\r1...
  class Spinner
    include Enumerable

    # The set of states this spinner can be in
    attr_reader :states

    # The character width of this spinner
    attr_reader :width

    # Create a spinner renderer that cycles between a set of predefined states.
    # If the list of states is not of equal size, smaller states will be left-
    # padded so the spinner is of constant width.
    #
    # A String of single characters is also supported.
    #
    # @param states [String, Array<String>] an array of spinner states
    # @return [Spinner]
    def initialize(states = ".:oO*")
      states = states.chars if states.is_a?(String)
      raise ArgumentError, "must specify at least two states" if states.size < 2

      @width = states.max(&:size)
      @states = states.map { |state| state.ljust(@width, ' ').freeze }
    end

    # Return the given spinner state.
    #
    # @param pos [Integer] the current render position, 0..size
    # @return [String] frozen representation of the bar
    def [](pos)
      @states[pos]
    end

    # Iterate over each state of the bar
    #
    # @yieldparam [String] bar a frozen String of the spinner
    # @return [nil, Enumerator]
    def each
      return enum_for(__method__) unless block_given?

      states.each do |state|
        yield state
      end
    end
  end
end
