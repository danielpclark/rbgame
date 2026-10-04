# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../../../lib", __dir__)

ENV["RBGAME_VIDEO_DRIVER"] ||= "offscreen"
ENV["RBGAME_AUDIO_DRIVER"] ||= "dummy"

require "minitest/autorun"
require "tmpdir"
require "gorillas"

module GorillasTest
  # A match on a known city: same seed, same skyline, same wind.
  def self.match(seed: 42, **options)
    Gorillas::Match.new(rng: Random.new(seed), **options)
  end

  # Terrain is a Surface, so SDL must be up.
  def self.init!
    Rbgame.init
  end

  # A KeyDown event for a key named by Symbol, or for a typed character.
  def self.key(sym, char = nil, shift: false)
    name = char || sym.to_s.capitalize
    code = char ? char.ord : Rbgame::Key.code(sym)
    Rbgame::Event::KeyDown.new(timestamp_ns: 0, window_id: 1, key: code, scancode: 0, name: name,
                               modifiers: shift ? Rbgame::Key::Mod::LSHIFT : 0, repeat: false)
  end

  # Runs a round until the block is satisfied, or fails.
  def self.run_until(round, seconds: 60, dt: 1 / 30.0)
    (seconds / dt).to_i.times do
      round.update(dt)
      return round if yield(round)
    end
    raise "round never reached the expected phase (#{round.phase.class})"
  end
end
