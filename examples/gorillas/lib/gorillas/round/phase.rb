# frozen_string_literal: true

module Gorillas
  class Round
    # The phases of a round, one class each. A phase receives time and
    # throws, acts on the round through its commands, and hands over to
    # the next phase with `round.enter`.
    module Phase
      class Base
        attr_reader :round

        def initialize(round)
          @round = round
        end

        def enter; end
        def update(_dt); end
        def banana = nil
        def explosion = nil

        def throw(_angle, _velocity)
          raise Rbgame::StateError, "cannot throw while #{self.class.name.split("::").last.downcase}"
        end

        private

        def match = round.match
        def thrower = round.thrower
      end

      # Waiting for the thrower's angle and velocity.
      class Aiming < Base
        def throw(angle, velocity)
          flight = Flight.new(round.shot_for(angle, velocity), thrower: round.thrower_gorilla)
          round.strike(thrower, :throwing)
          round.enter(Flying.new(round, flight))
        end
      end

      # The banana is in the air; every simulated step looks for an impact.
      class Flying < Base
        TIME_SCALE = 4.5 # simulated seconds per real second
        ARM_DOWN_AFTER = 0.4

        attr_reader :flight

        def initialize(round, flight)
          super(round)
          @flight = flight
        end

        def banana = flight.banana

        def update(dt)
          flight.advance(dt * TIME_SCALE) { |flight| land(impact_of(flight)) }
          round.strike(thrower, :at_ease) if flight.time >= ARM_DOWN_AFTER && round.flying?
        end

        private

        # What the banana is touching, if anything, as an Outcome.
        def impact_of(flight)
          point = flight.position
          if flight.off_field?
            Outcome.missed(point)
          elsif round.sun.hit?(point)
            round.startle_sun
            nil
          elsif (victim = round.gorilla_hit_at(point, by: flight))
            Outcome.gorilla(point, victim)
          elsif round.terrain.solid?(point)
            Outcome.building(point)
          end
        end

        # True once the flight is over, which stops the advance early.
        def land(outcome)
          return false unless outcome

          round.conclude(outcome)
          if outcome.missed?
            round.pass_turn
            round.enter(Aiming.new(round))
          else
            round.announce(outcome.hit_gorilla? ? :gorilla_hit : :explosion)
            round.enter(Exploding.new(round, Explosion.new(outcome.point, max_radius: outcome.explosion_radius)))
          end
          true
        end
      end

      # Fire grows, then a crater is left and the round moves on.
      class Exploding < Base
        attr_reader :explosion

        def initialize(round, explosion)
          super(round)
          @explosion = explosion
        end

        def update(dt)
          explosion.update(dt)
          return unless explosion.finished?

          round.crater(explosion)
          if round.outcome.hit_gorilla?
            round.award(round.winner)
            round.enter(Dancing.new(round, round.winner))
          else
            round.pass_turn
            round.enter(Aiming.new(round))
          end
        end
      end

      # The winner's victory dance, arms alternating to the beat.
      class Dancing < Base
        SECONDS = 2.5
        BEATS_PER_SECOND = 4

        def initialize(round, winner)
          super(round)
          @winner = winner
          @elapsed = 0.0
        end

        def update(dt)
          @elapsed += dt
          round.dance(@winner, (@elapsed * BEATS_PER_SECOND).floor)
          round.enter(Over.new(round)) if @elapsed >= SECONDS
        end
      end

      # Somebody was hit; nothing more happens here.
      class Over < Base; end
    end
  end
end
