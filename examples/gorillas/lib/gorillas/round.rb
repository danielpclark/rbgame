# frozen_string_literal: true

module Gorillas
  # One city, two gorillas, bananas until somebody is hit.
  #
  # Round is the model of play and knows nothing of keys or pixels. What
  # happens next depends on its phase, and each phase is an object
  # (Round::Phase) that handles time and throws for it:
  #
  #   Aiming --throw--> Flying --impact--> Exploding --> Aiming (a miss)
  #                        \--off field--> Aiming        \--> Dancing --> Over
  #
  # Things worth hearing (a sun hit, an explosion, the victory dance) go to
  # a listener, so sound stays out of the model.
  class Round
    NO_LISTENER = ->(_event) {}

    attr_reader :match, :skyline, :terrain, :wind, :sun, :thrower, :phase, :outcome, :listener

    def initialize(match, rng: match.rng, listener: NO_LISTENER)
      @match = match
      @listener = listener
      @skyline = Skyline.generate(rng: rng)
      @terrain = Terrain.new(skyline)
      @wind = Wind.random(rng: rng)
      @sun = Sun.new
      @gorillas = place_gorillas(rng)
      @thrower = match.opening_player
      @outcome = nil
      @phase = Phase::Aiming.new(self)
    end

    # --- what the scenes ask -------------------------------------------

    def gorillas = @gorillas.values
    def gorilla_of(player) = @gorillas.fetch(player.side)
    def thrower_gorilla = gorilla_of(thrower)
    def target = match.opponent_of(thrower)

    def aiming? = phase.is_a?(Phase::Aiming)
    def flying? = phase.is_a?(Phase::Flying)
    def exploding? = phase.is_a?(Phase::Exploding)
    def dancing? = phase.is_a?(Phase::Dancing)
    def over? = phase.is_a?(Phase::Over)

    def banana = phase.banana
    def explosion = phase.explosion
    def winner = outcome&.hit_gorilla? ? match.opponent_of(outcome.victim) : nil

    # A Shot for a player from where they stand, for aiming and for the
    # autoplayer to think with.
    def shot_for(angle, velocity, player = thrower)
      Shot.new(origin: gorilla_of(player).hand, angle: angle, velocity: velocity,
               direction: player.direction, gravity: match.gravity, wind: wind)
    end

    def throw(angle, velocity) = tap { phase.throw(angle, velocity) }

    def update(dt)
      @sun = sun.after(dt)
      phase.update(dt)
      self
    end

    # --- what the phases do to the round -------------------------------

    def enter(phase)
      @phase = phase
      phase.enter
    end

    def strike(player, pose_name)
      gorilla = gorilla_of(player)
      @gorillas[player.side] = pose_name == :throwing ? gorilla.throwing : gorilla.at_ease
    end

    def dance(player, beat)
      @gorillas[player.side] = gorilla_of(player).dancing(beat)
    end

    def startle_sun
      return if sun.shocked?

      @sun = sun.startled
      announce(:sun_hit)
    end

    def conclude(outcome)
      @outcome = outcome
    end

    def crater(explosion) = terrain.crater(explosion.center, explosion.crater_radius)

    def award(player)
      match.score!(player)
      announce(:victory)
    end

    def pass_turn
      strike(thrower, :at_ease)
      @thrower = match.opponent_of(thrower)
    end

    # The player (if any) whose gorilla is at `point`. A thrower is safe
    # from their own banana until it has left their hands.
    def gorilla_hit_at(point, by:)
      match.players.find do |player|
        next false if player.equal?(thrower) && !by.left_home?

        gorilla_of(player).hit?(point)
      end
    end

    def announce(event) = listener.call(event)

    private

    def place_gorillas(rng)
      left_roof, right_roof = skyline.gorilla_roofs(rng)
      { left: Gorilla.new(feet: left_roof, facing: :right), right: Gorilla.new(feet: right_roof, facing: :left) }
    end
  end
end
