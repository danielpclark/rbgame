# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../../../lib", __dir__)

ENV["RBGAME_VIDEO_DRIVER"] ||= "offscreen"
ENV["RBGAME_AUDIO_DRIVER"] ||= "dummy"

require "minitest/autorun"
require "tmpdir"
require "gorillas"

Gorillas::Sounds.enabled = false

module GorillasTest
  # A match on a known city: same seed, same skyline, same wind.
  def self.match(seed: 42, **options)
    Gorillas::Match.new(rng: Random.new(seed), **options)
  end

  # Terrain is a Surface, so SDL must be up.
  def self.init!
    Rbgame.init
  end
end
