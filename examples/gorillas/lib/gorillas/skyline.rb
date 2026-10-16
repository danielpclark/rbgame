# frozen_string_literal: true

module Gorillas
  # The row of buildings across the field, built the way MakeCityScape
  # did: pick a slope for the city, then walk left to right, each
  # building a random width, and a random height on top of the slope's
  # trend.
  class Skyline
    include Enumerable

    MIN_WIDTH = 38
    MAX_WIDTH = 74
    MIN_HEIGHT = 10
    MAX_HEIGHT = 230
    HEIGHT_STEP = 10   # HtInc: the slope's step per building
    RANDOM_HEIGHT = 120 # the height rolled on top of the trend
    GAP = 2

    # The shape of a city: where its trend starts and how it moves with
    # each building, given how far along the field it stands.
    class Slope
      attr_reader :name

      def initialize(name, starts:, &step)
        @name = name
        @starts = starts
        @step = step
      end

      def starting_trend = @starts

      # The change in the trend before the next building, in pixels.
      def step_at(x) = @step.call(x)

      ALL = [
        new(:rising, starts: 15) { HEIGHT_STEP },
        new(:falling, starts: 130) { -HEIGHT_STEP },
        new(:valley, starts: 15) { |x| Field.left_half?(x) ? 2 * HEIGHT_STEP : -2 * HEIGHT_STEP },
        new(:peak, starts: 130) { |x| Field.left_half?(x) ? -2 * HEIGHT_STEP : 2 * HEIGHT_STEP }
      ].freeze

      # One roll of six: the valley three times out of six, as the
      # original's "V slope - most common".
      def self.pick(rng)
        case rng.rand(1..6)
        when 1 then ALL[0]
        when 2 then ALL[1]
        when 6 then ALL[3]
        else ALL[2]
        end
      end
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
        trend = @slope.starting_trend
        loop do
          trend += @slope.step_at(x)
          width = [MIN_WIDTH + @rng.rand(MAX_WIDTH - MIN_WIDTH + 1), Field::WIDTH - x - GAP].min
          height = (trend + 1 + @rng.rand(RANDOM_HEIGHT)).clamp(MIN_HEIGHT, MAX_HEIGHT)
          yield Building.build(x: x, width: width, height: height, color: Palette::BUILDINGS.sample(random: @rng), rng: @rng)
          x += width + GAP
          break if x > Field::WIDTH - HEIGHT_STEP
        end
      end
    end

    attr_reader :buildings, :slope

    def self.generate(rng: Random.new)
      slope = Slope.pick(rng)
      new(Architect.new(slope, rng).to_a, slope: slope.name)
    end

    def initialize(buildings, slope: :valley)
      @buildings = buildings.freeze
      @slope = slope
    end

    def each(&) = buildings.each(&)
    def length = buildings.length
    def [](index) = buildings[index]
    def building_under(x) = find { |building| building.spans?(x) }

    # Roofs for the two gorillas: the second or third building from each
    # end, as PlaceGorillas chose them.
    def gorilla_roofs(rng)
      last = length - 1
      left = (1 + rng.rand(2)).clamp(0, last)
      right = (last - 1 - rng.rand(2)).clamp(left + 1, last)
      [self[left].roof, self[right].roof]
    end
  end
end
