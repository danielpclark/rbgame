# frozen_string_literal: true

module Gorillas
  # The sun at the top of the field. It smiles, unless a banana just went
  # through it, in which case it is as shocked as you would be, for a while.
  class Sun < Data.define(:center, :shock)
    RADIUS = 12
    SHOCK_SECONDS = 2.0

    def initialize(center: Field::SUN_CENTER, shock: 0.0)
      super(center: Rbgame::Vector.coerce(center), shock: shock)
    end

    def shocked? = shock.positive?
    def hit?(point) = center.distance_to(point) <= RADIUS + 2
    def startled = with(shock: SHOCK_SECONDS)
    def after(seconds) = shocked? ? with(shock: [shock - seconds, 0.0].max) : self
  end
end
