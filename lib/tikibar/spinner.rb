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

    # The last state of the spinner
    attr_reader :finish

    # The character width of this spinner
    attr_reader :width

    # Create a spinner renderer that cycles between a set of predefined states.
    # If the list of states is not of equal size, smaller states will be left-
    # padded so the spinner is of constant width.
    #
    # A String of single characters is also supported.
    #
    # @param states [String, Array<String>] an array of spinner states
    # @param finish [String] An optional ending state for the spinner
    # @return [Spinner]
    def initialize(states = ".:oO*", finish = "", reverse: false)
      states = states.chars if states.is_a?(String)
      states += states.reverse.drop(1) if reverse

      @width = states.map(&:size).max
      @finish = finish.ljust(@width).freeze
      @states = states.map { |state| state.ljust(@width).freeze }.freeze
    end

    # Return the given spinner state.
    #
    # @param pos [Integer] a wrapping state number for the spinner
    # @return [String] frozen representation of the bar
    def [](pos)
      states[pos % states.size]
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
