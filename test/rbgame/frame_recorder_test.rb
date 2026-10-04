# frozen_string_literal: true

require "test_helper"

class FrameRecorderTest < Minitest::Test
  FakeScreen = Struct.new(:saved) do
    def screenshot(path) = saved << path
  end

  def test_no_directory_means_no_recording
    recorder = Rbgame::FrameRecorder.for(nil)
    screen = FakeScreen.new([])
    3.times { |frame| recorder.record(screen, frame) }
    assert_empty screen.saved
  end

  def test_records_every_nth_frame_into_the_directory
    Dir.mktmpdir do |dir|
      recorder = Rbgame::FrameRecorder.for(dir, every: 2)
      screen = FakeScreen.new([])
      5.times { |frame| recorder.record(screen, frame) }
      assert_equal %w[frame-00000.bmp frame-00002.bmp frame-00004.bmp], screen.saved.map { |p| File.basename(p) }
      assert screen.saved.all? { |p| p.start_with?(dir) }
    end
  end

  def test_creates_the_directory
    Dir.mktmpdir do |dir|
      target = File.join(dir, "frames")
      Rbgame::FrameRecorder.for(target)
      assert File.directory?(target)
    end
  end
end
