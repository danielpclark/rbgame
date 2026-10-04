# frozen_string_literal: true

module Gorillas
  # What the command line asked for.
  Options = Data.define(:autoplay, :names, :play_to, :gravity, :seed, :sound, :accuracy, :scale) do
    def initialize(autoplay: false, names: ["Player 1", "Player 2"], play_to: 3, gravity: 9.8, seed: nil,
                   sound: true, accuracy: 0.6, scale: 2)
      super
    end
  end

  # The window, the loop, and the scene on stage. Everything game-specific
  # is in the scenes and the model; this class only wires them to rbgame.
  class Game < Rbgame::Game
    configure title: "Ruby GORILLAS", fps: 60, logical: Field::SIZE

    attr_reader :options, :match, :rng

    def initialize(options = Options.new)
      super()
      @options = options
      @rng = options.seed ? Random.new(options.seed) : Random.new
      @match = nil
      Sounds.enabled = options.sound
      self.class.configure size: Field::SIZE * options.scale
    end

    def setup
      switch(Scenes::Intro.new(self))
    end

    def start_match(names:, play_to:, gravity:)
      @match = Match.new(names: names, play_to: play_to, gravity: gravity, rng: rng)
    end

    def on_event(event)
      case event
      in Rbgame::Event::KeyDown[sym: :escape] then stop
      in Rbgame::Event::KeyDown[sym: :q] if !@scene.is_a?(Scenes::Setup) then stop
      else
        switch(@scene.handle(event))
        super
      end
    end

    def update(dt) = switch(@scene.update(dt))
    def draw(screen) = @scene.draw(screen)

    private

    def switch(scene)
      return unless scene

      @scene = scene
      @scene.enter
    end
  end
end
