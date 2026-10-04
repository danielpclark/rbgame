# frozen_string_literal: true

module Gorillas
  # What the command line asked for.
  class Options < Data.define(:autoplay, :names, :play_to, :gravity, :seed, :sound, :accuracy, :scale)
    def initialize(autoplay: false, names: ["Player 1", "Player 2"], play_to: 3, gravity: 9.8, seed: nil,
                   sound: true, accuracy: 0.6, scale: 2)
      super
    end

    # The setup questions, answered from the command line.
    def setup_answers = { name1: names[0], name2: names[1], play_to: play_to, gravity: gravity }
  end

  # The window, the loop, and the scene on stage. Everything about the game
  # lives in the scenes, the model and the views; this class only wires
  # them to rbgame and chooses who is at the controls.
  class Game < Rbgame::Game
    configure title: "Ruby GORILLAS", fps: 60, logical: Field::SIZE

    attr_reader :options, :match, :rng, :controller, :jukebox, :autoplayer

    def initialize(options = Options.new)
      super()
      @options = options
      @rng = options.seed ? Random.new(options.seed) : Random.new
      @jukebox = Jukebox.for(options.sound)
      @autoplayer = Autoplayer.new(rng: rng, accuracy: options.accuracy) if options.autoplay
      @controller = options.autoplay ? Controllers::Autopilot.new : Controllers::Keyboard.new
      @match = nil
      self.class.configure size: Field::SIZE * options.scale
    end

    def setup = switch(Scenes::Intro.new(self))

    def start_match(names:, play_to:, gravity:)
      @match = Match.new(names: names, play_to: play_to, gravity: gravity, rng: rng)
    end

    def on_event(event)
      case event
      in Rbgame::Event::KeyDown[sym: :escape] then stop
      in Rbgame::Event::KeyDown[sym: :q] unless @scene.is_a?(Scenes::Setup) then stop
      else
        switch(@scene.handle(event))
        super
      end
    end

    def update(dt) = switch(@scene.update(dt))
    def draw(screen) = @scene.draw(screen)
    def teardown = @scene&.leave

    private

    def switch(next_scene)
      return unless next_scene

      @scene&.leave
      @scene = next_scene
      @scene.enter
    end
  end
end
