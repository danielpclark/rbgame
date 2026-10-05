# frozen_string_literal: true

require "test_helper"

# Runs on SDL's dummy camera driver, which has no cameras: what a game sees
# on a machine without a webcam, and the null object it gets instead.
class CameraTest < Minitest::Test
  Camera = Rbgame::Camera
  Event = Rbgame::Event
  Vector = Rbgame::Vector

  def test_the_dummy_driver_is_listed_and_in_use
    assert_includes Camera.drivers, "dummy"
    assert_equal "dummy", Camera.driver
    assert Rbgame.initialized?(:camera)
  end

  def test_no_camera_means_an_empty_list_and_none
    assert_equal [], Camera.all
    refute Camera.any?
    assert Camera.first.none?
    assert Camera.find(42).none?
    assert Camera.open.none?
    assert Camera.open(size: [640, 480], fps: 30).none?
  end

  def test_none_is_safe_to_use_as_a_camera
    none = Camera::None.new
    assert_nil none.frame
    assert_nil none.format
    assert_equal [], none.formats
    assert none.denied?
    refute none.approved?
    assert_equal :denied, none.permission
    assert_equal "no camera", none.name
    assert_same none, none.open
    assert_same none, none.close
  end

  def test_formats_read_as_sizes_and_rates
    format = Camera.format_from([1280, 720, 30_000, 1001])
    assert_equal Vector[1280, 720], format.size
    assert_in_delta 29.97, format.fps, 0.001
    assert_equal "1280x720 at 29.97 fps", format.to_s
  end

  def test_device_events_name_the_camera
    event = Event.from_hash(type: :camera_added, timestamp_ns: 0, which: 7)
    assert_instance_of Event::CameraAdded, event
    assert event.camera.none?, "an unplugged camera is None"

    case Event.from_hash(type: :camera_approved, timestamp_ns: 0, which: 7)
    in Event::CameraApproved[which: 7, camera:] then assert camera.none?
    end
    assert_instance_of Event::CameraDenied, Event.from_hash(type: :camera_denied, timestamp_ns: 0, which: 7)
    assert_instance_of Event::CameraRemoved, Event.from_hash(type: :camera_removed, timestamp_ns: 0, which: 7)
  end
end
