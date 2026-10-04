# frozen_string_literal: true

module Gorillas
  # A player: a name, a score, and the side of the field they throw from.
  class Player
    attr_reader :name, :side, :score

    def initialize(name, side:)
      @name = name
      @side = side
      @score = 0
    end

    def score! = @score += 1
    def left? = side == :left
    def facing = left? ? :right : :left
    def direction = left? ? 1 : -1
    def to_s = name
  end
end
