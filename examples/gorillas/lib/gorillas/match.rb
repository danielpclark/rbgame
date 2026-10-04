# frozen_string_literal: true

module Gorillas
  # The settings and running score of a game: who plays, to how many
  # points, under what gravity.
  class Match
    DEFAULT_POINTS = 3
    EARTH_GRAVITY = 9.8

    attr_reader :players, :play_to, :gravity, :rng, :rounds

    def initialize(names: ["Player 1", "Player 2"], play_to: DEFAULT_POINTS, gravity: EARTH_GRAVITY, rng: Random.new)
      raise ArgumentError, "play to at least 1 point" unless play_to.positive?
      raise ArgumentError, "gravity must pull downwards" unless gravity.positive?

      @players = [Player.new(names[0], side: :left), Player.new(names[1], side: :right)].freeze
      @play_to = play_to
      @gravity = gravity.to_f
      @rng = rng
      @rounds = 0
    end

    def left = players[0]
    def right = players[1]
    def opponent_of(player) = player.equal?(left) ? right : left
    def total_points = players.sum(&:score)
    def leader = players.max_by(&:score)

    def score!(player)
      player.score!
      @rounds += 1
    end

    def over? = total_points >= play_to
    def winner = over? ? leader : nil

    # The loser of the last round throws first; player 1 opens the match.
    def opening_player = rounds.zero? ? left : opponent_of(leader)

    def new_round(listener: Round::NO_LISTENER) = Round.new(self, listener: listener)
  end
end
