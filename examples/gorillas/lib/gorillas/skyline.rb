# frozen_string_literal: true

module Gorillas
  # The row of buildings across the field, generated the way GORILLA.BAS
  # did: pick a slope for the city (rising, falling, a V, a peak, or
  # random), then walk left to right rolling widths and heights.
  class Skyline
    include Enumerable

    SLOPES = %i[rising falling valley peak random random].freeze
    MIN_WIDTH = 37
    EXTRA_WIDTH = 120
    MIN_HEIGHT = 20
    MAX_HEIGHT = 230
    HEIGHT_STEP = 10
    GAP = 2

    attr_reader :buildings, :slope

    def self.generate(rng: Random.new)
      slope = SLOPES[rng.rand(SLOPES.length)]
      new(build(slope, rng), slope: slope)
    end

    def initialize(buildings, slope: :random)
      @buildings = buildings.freeze
      @slope = slope
    end

    def each(&) = buildings.each(&)
    def length = buildings.length
    def [](index) = buildings[index]

    def building_under(x) = buildings.find { |b| x >= b.x && x < b.right }

    class << self
      private

      def build(slope, rng)
        buildings = []
        x = GAP
        height = starting_height(slope, rng)
        width_so_far = 0

        while x < Field::WIDTH - MIN_WIDTH
          width = [MIN_WIDTH + rng.rand(EXTRA_WIDTH / 2), Field::WIDTH - x - GAP].min
          height = next_height(slope, height, x, rng)
          color = Palette::BUILDINGS[rng.rand(Palette::BUILDINGS.length)]
          buildings << Building.build(x: x, width: width, height: height, color: color, rng: rng)
          x += width + GAP
          width_so_far += width
        end
        buildings
      end

      def starting_height(slope, rng)
        case slope
        when :rising, :valley then MIN_HEIGHT + rng.rand(HEIGHT_STEP * 3)
        when :falling, :peak then MAX_HEIGHT - rng.rand(HEIGHT_STEP * 3)
        else MIN_HEIGHT + rng.rand(MAX_HEIGHT - MIN_HEIGHT)
        end
      end

      def next_height(slope, height, x, rng)
        half = Field::WIDTH / 2
        direction =
          case slope
          when :rising then 1
          when :falling then -1
          when :valley then x < half ? -1 : 1
          when :peak then x < half ? 1 : -1
          else [-1, 1][rng.rand(2)]
          end
        step = rng.rand(HEIGHT_STEP * 6) * direction
        (height + step).clamp(MIN_HEIGHT, MAX_HEIGHT)
      end
    end
  end
end
