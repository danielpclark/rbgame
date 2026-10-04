# frozen_string_literal: true

module Gorillas
  module Scenes
    # A screen of the game. The game hands each scene events and time and
    # asks it to draw; a scene moves on by returning the next scene from
    # `handle` or `update`, or nil to stay.
    class Base
      attr_reader :game

      def initialize(game)
        @game = game
        @elapsed = 0.0
      end

      def enter; end
      def leave; end
      def handle(_event) = nil
      def draw(_canvas); end

      def update(dt)
        @elapsed += dt
        tick(dt)
      end

      private

      attr_reader :elapsed

      def tick(_dt) = nil
      def options = game.options
      def match = game.match
      def controller = game.controller
      def jukebox = game.jukebox
      def any_key?(event) = event.is_a?(Rbgame::Event::KeyDown) && !event.repeat?
      def typography(canvas) = View::Typography.new(canvas)
    end
  end
end
