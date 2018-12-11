# frozen_string_literal: true

module Tikibar
  class Eta
    include Monotime

    attr_reader :start

    ZeroDuration = Duration.nanos(0)

    def initialize
      @buf = []
      @last_idx = 0
      @start = nil
      @initial = 0
      @cap = 10
    end

    def step(now, value)
      if start.nil?
        @start = now
        @initial = value
      end

      item = if value == 0
        ZeroDuration
      else
        (start.elapsed / (value - @initial).to_f.clamp(0.1, 999999.9))
      end

      if @buf.size >= @cap
        idx = @last_idx % @buf.size
        @buf[idx] = item
      else
        @buf << item
      end
      @last_idx += 1
    end

    def time_per_step
      if @buf.empty?
        ZeroDuration
      else
        @buf.inject { |a,b| a + b } / @buf.size
      end
    end
  end
end
