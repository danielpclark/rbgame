# frozen_string_literal: true

require "fileutils"

module Rbgame
  # Saves a game's frames as BMP files, for headless runs and tests.
  # `FrameRecorder.for(nil)` is a recorder that records nothing, so the
  # game loop never has to ask whether recording is on.
  class FrameRecorder
    class Nothing
      def record(_screen, _frame) = self
    end

    def self.for(directory, every: 1)
      directory ? new(directory, every: every) : Nothing.new
    end

    attr_reader :directory, :every

    def initialize(directory, every: 1)
      @directory = directory
      @every = [every, 1].max
      FileUtils.mkdir_p(directory)
    end

    def record(screen, frame)
      screen.screenshot(path_for(frame)) if (frame % every).zero?
      self
    end

    def path_for(frame) = File.join(directory, format("frame-%05d.bmp", frame))
  end
end
