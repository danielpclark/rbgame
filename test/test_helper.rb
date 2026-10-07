# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Tests never need a real window: run on SDL's offscreen driver whatever the
# machine has, so results are the same everywhere (CI included).
ENV["RBGAME_VIDEO_DRIVER"] ||= "offscreen"
ENV["RBGAME_AUDIO_DRIVER"] ||= "dummy"
ENV["RBGAME_CAMERA_DRIVER"] ||= "dummy"

require "minitest/autorun"
require "tmpdir"
require "rbgame"

module RbgameTest
  # The driver the tests were told to use, and whether it can show a window.
  def self.video_driver = ENV.fetch("RBGAME_VIDEO_DRIVER")
  def self.headless? = Rbgame::VideoDriver.headless?(video_driver)

  # A screen for integration tests, opened once per process.
  def self.screen
    @screen ||= begin
      Rbgame.init
      Rbgame::Display.set_mode([200, 120], title: "rbgame tests")
    end
  end

  # A Sound written as a 16-bit PCM WAV file, for the loaders to read back.
  def self.write_wav(path, sound)
    data = sound.pcm
    header = ["RIFF", 36 + data.bytesize, "WAVE", "fmt ", 16, 1, sound.channels, sound.rate,
              sound.rate * sound.channels * 2, sound.channels * 2, 16, "data", data.bytesize]
    File.binwrite(path, header.pack("a4Va4a4VvvVVvva4V") + data)
  end

  # The same screen opened with other options; `screen` reopens the usual
  # one afterwards, so tests stay independent of each other.
  def self.reopen_screen(**options)
    @screen = nil
    Rbgame::Display.set_mode([200, 120], title: "rbgame tests", **options)
  end
end
