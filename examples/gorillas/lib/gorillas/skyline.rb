# frozen_string_literal: true

module Gorillas
  # The row of buildings across the field, built the way MakeCityScape
  # did: pick a slope for the city, then walk left to right rolling widths
  # and heights.
  class Skyline
    include Enumerable

    MIN_WIDTH = 37
    EXTRA_WIDTH = 60
    MIN_HEIGHT = 20
    MAX_HEIGHT = 230
    HEIGHT_STEP = 10
    GAP = 2

    # The shape of a city: where it starts and which way each next
    # building leans, given how far along the field it stands.
    class Slope
      attr_reader :name

      def initialize(name, starts:, &lean)
        @name = name
        @starts = starts
        @lean = lean
      end

      def starting_height(rng)
        case @starts
        when :low then MIN_HEIGHT + rng.rand(HEIGHT_STEP * 3)
        when :high then MAX_HEIGHT - rng.rand(HEIGHT_STEP * 3)
        else MIN_HEIGHT + rng.rand(MAX_HEIGHT - MIN_HEIGHT)
        end
      end

      # +1 for taller, -1 for shorter.
      def lean_at(x, rng) = @lean.call(x, rng)

      ALL = [
        new(:rising, starts: :low) { 1 },
        new(:falling, starts: :high) { -1 },
        new(:valley, starts: :low) { |x, _| Field.left_half?(x) ? -1 : 1 },
        new(:peak, starts: :high) { |x, _| Field.left_half?(x) ? 1 : -1 },
        new(:random, starts: :anywhere) { |_, rng| [-1, 1].sample(random: rng) }
      ].freeze

      # Random twice as often as any other, as the original rolled it.
      def self.pick(rng) = (ALL + [ALL.last]).sample(random: rng)
    end

    # Walks the field from left to right, one building at a time.
    class Architect
      include Enumerable

      def initialize(slope, rng)
        @slope = slope
        @rng = rng
      end

      def each
        return enum_for(:each) unless block_given?

        x = GAP
        height = @slope.starting_height(@rng)
        while x < Field::WIDTH - MIN_WIDTH
          width = [MIN_WIDTH + @rng.rand(EXTRA_WIDTH), Field::WIDTH - x - GAP].min
          height = next_height(height, x)
          yield Building.build(x: x, width: width, height: height, color: Palette::BUILDINGS.sample(random: @rng), rng: @rng)
          x += width + GAP
        end
      end

      private

      def next_height(height, x)
        step = @rng.rand(HEIGHT_STEP * 6) * @slope.lean_at(x, @rng)
        (height + step).clamp(MIN_HEIGHT, MAX_HEIGHT)
      end
    end

    attr_reader :buildings, :slope

    def self.generate(rng: Random.new)
      slope = Slope.pick(rng)
      new(Architect.new(slope, rng).to_a, slope: slope.name)
    end

    def initialize(buildings, slope: :random)
      @buildings = buildings.freeze
      @slope = slope
    end

    def each(&) = buildings.each(&)
    def length = buildings.length
    def [](index) = buildings[index]
    def building_under(x) = find { |building| building.spans?(x) }

    # Roofs for the two gorillas: near each end, never the very edge.
    def gorilla_roofs(rng)
      last = length - 1
      left = (1 + rng.rand(2)).clamp(0, last)
      right = (last - 1 - rng.rand(2)).clamp(left + 1, last)
      [self[left].roof, self[right].roof]
    end
  end
end
