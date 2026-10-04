# frozen_string_literal: true

module Gorillas
  # One city, two gorillas, bananas until somebody is hit. Round holds the
  # whole model of play and nothing about keys or pixels on the screen: the
  # scene feeds it throws and time, and asks what happened.
  #
  # Phases: :aiming -> :flying -> :exploding -> (:dancing | :aiming) -> :over
  class Round
    TIME_SCALE = 4.5 # simulated seconds per real second while a banana flies
    DANCE_SECONDS = 2.5
    SUN_SHOCK_SECONDS = 2.0

    Outcome = Data.define(:kind, :point, :victim) do
      def hit_gorilla? = kind == :gorilla
    end

    attr_reader :match, :skyline, :terrain, :gorillas, :sun, :wind, :thrower, :phase, :outcome, :flight, :explosion

    def initialize(match, rng: match.rng)
      @match = match
      @rng = rng
      @skyline = Skyline.generate(rng: rng)
      @terrain = Terrain.new(skyline)
      @wind = Wind.random(rng: rng)
      @sun = Sun.new
      @gorillas = place_gorillas
      @thrower = match.opening_player
      @phase = :aiming
      @outcome = nil
      @flight = nil
      @explosion = nil
      @timer = 0.0
      @banana_frame = 0
    end

    def gorilla_of(player) = gorillas.fetch(player.side)
    def thrower_gorilla = gorilla_of(thrower)
    def target = match.opponent_of(thrower)
    def aiming? = phase == :aiming
    def flying? = phase == :flying
    def over? = phase == :over
    def winner = over? ? outcome&.victim&.then { |v| match.opponent_of(v) } : nil
    def banana_position = flight&.position
    def banana_frame = @banana_frame

    # A Shot for the current thrower, for the autoplayer to think with.
    def shot_for(angle, velocity, player = thrower)
      gorilla = gorilla_of(player)
      Shot.new(origin: gorilla.hand, angle: angle, velocity: velocity, direction: player.direction,
               gravity: match.gravity, wind: wind)
    end

    def throw(angle, velocity)
      raise Rbgame::StateError, "not aiming" unless aiming?

      @flight = Flight.new(shot_for(angle, velocity), thrower_gorilla)
      gorillas[thrower.side] = thrower_gorilla.with(pose: thrower_gorilla.throwing_pose)
      @phase = :flying
      @timer = 0.0
      self
    end

    def update(dt)
      @timer += dt
      case phase
      when :flying then update_flight(dt)
      when :exploding then update_explosion(dt)
      when :dancing then update_dance
      end
      @sun = sun.calm if sun.shocked? && @timer > SUN_SHOCK_SECONDS && !flying?
      self
    end

    private

    # The banana in the air: where it is, and whether it has left its
    # thrower's hands yet (it starts inside the thrower, who is not a target).
    class Flight
      attr_reader :shot, :t, :position

      def initialize(shot, thrower_gorilla)
        @shot = shot
        @thrower_bounds = thrower_gorilla.bounds.inflate(6)
        @t = 0.0
        @position = shot.position(0)
        @cleared_thrower = false
      end

      def advance(dt)
        @t += dt
        @position = shot.position(@t)
        @cleared_thrower ||= !@thrower_bounds.contains?(@position)
        self
      end

      def cleared_thrower? = @cleared_thrower
      def off_field? = position.y > Field::HEIGHT || position.x.negative? || position.x > Field::WIDTH
    end

    def place_gorillas
      count = skyline.length
      left_index = 1 + @rng.rand(2).clamp(0, count - 1)
      right_index = (count - 2 - @rng.rand(2)).clamp(left_index + 1, count - 1)
      {
        left: Gorilla.new(feet: skyline[left_index].roof, facing: :right),
        right: Gorilla.new(feet: skyline[right_index].roof, facing: :left)
      }
    end

    def update_flight(dt)
      sim = dt * TIME_SCALE
      steps = [(sim / 0.05).ceil, 1].max
      step = sim / steps
      steps.times do
        flight.advance(step)
        @banana_frame = Banana.frame_for(flight.t)
        break if resolve_collision
      end
      lower_arm
    end

    def resolve_collision
      pos = flight.position
      if flight.off_field?
        finish_throw(:missed)
      elsif sun.hit?(pos)
        unless sun.shocked?
          @sun = sun.shock
          Sounds.play(:sun_hit)
        end
        false
      elsif (victim = gorilla_hit(pos))
        explode(pos, Explosion::GORILLA_RADIUS, Outcome.new(kind: :gorilla, point: pos, victim: victim))
        Sounds.play(:gorilla_hit)
      elsif terrain.solid?(pos)
        explode(pos, Explosion::BUILDING_RADIUS, Outcome.new(kind: :building, point: pos, victim: nil))
        Sounds.play(:explosion)
      else
        false
      end
    end

    def gorilla_hit(pos)
      match.players.find do |player|
        next false if player.equal?(thrower) && !flight.cleared_thrower?

        gorilla_of(player).hit?(pos)
      end
    end

    def explode(pos, radius, outcome)
      @outcome = outcome
      @explosion = Explosion.new(pos, max_radius: radius)
      @phase = :exploding
      true
    end

    def finish_throw(kind)
      @outcome = Outcome.new(kind: kind, point: flight.position, victim: nil)
      next_turn
      true
    end

    def update_explosion(dt)
      explosion.update(dt)
      return unless explosion.finished?

      terrain.crater(explosion.center, explosion.max_radius)
      @explosion = nil
      if outcome.hit_gorilla?
        match.score!(match.opponent_of(outcome.victim))
        start_dance
      else
        next_turn
      end
    end

    def start_dance
      @phase = :dancing
      @timer = 0.0
      Sounds.play(:victory)
    end

    def update_dance
      winner = match.opponent_of(outcome.victim)
      pose = (@timer * 4).floor.even? ? :left_up : :right_up
      gorillas[winner.side] = gorilla_of(winner).with(pose: pose)
      @phase = :over if @timer >= DANCE_SECONDS
    end

    def lower_arm
      return if flight.t < 0.4 || !flying?

      gorillas[thrower.side] = thrower_gorilla.with(pose: :down)
    end

    def next_turn
      gorillas[thrower.side] = thrower_gorilla.with(pose: :down)
      @flight = nil
      @thrower = match.opponent_of(thrower)
      @phase = :aiming
      @timer = 0.0
    end
  end
end
