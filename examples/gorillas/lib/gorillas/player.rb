# frozen_string_literal: true

module Gorillas
  # A player: name, score, and which side of the field they play from.
  class Player
    attr_reader :name, :side
    attr_accessor :score

    def initialize(name, side:)
      @name = name
      @side = side
      @score = 0
    end

    def left? = side == :left
    def facing = left? ? :right : :left
    def direction = left? ? 1 : -1
    def to_s = name
  end
end
