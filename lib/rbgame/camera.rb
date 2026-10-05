# frozen_string_literal: true

module Rbgame
  # Capture devices through SDL's camera API: webcams on Linux (V4L2 and
  # PipeWire) and Windows (Media Foundation). A camera may need the user's
  # permission; until it is approved there are no frames.
  #
  #   camera = Camera.open                 # the first camera, Camera::None without one
  #   if (shot = camera.frame)             # the newest frame as a Surface, or nil
  #     shot.with_texture(screen) { |texture| screen.draw(texture, at: [0, 0]) }
  #   end
  #
  #   Events.each do |event|
  #     case event
  #     in Event::CameraApproved then say "camera on"
  #     in Event::CameraAdded[camera:] then camera.open
  #     end
  #   end
  class Camera
    # A size and frame rate a camera offers, or was opened at.
    Format = Data.define(:width, :height, :fps) do
      def size = Vector.new(width, height)
      def to_s = "#{width}x#{height} at #{fps.round(2)} fps"
    end

    # A camera as listed, before it is opened.
    Device = Data.define(:id, :name, :position) do
      def formats = Native::Camera.formats_for(id).map { |spec| Camera.format_from(spec) }

      # `size:` and `fps:` ask for a format; SDL converts frames to it.
      def open(size: nil, fps: nil)
        width, height = size && Vector.coerce(size).to_a
        numerator, denominator = fps && fps.to_r.then { |rate| [rate.numerator, rate.denominator] }
        Camera.new(Native::Camera.open(id, width, height, numerator, denominator), device: self)
      end

      def none? = false
    end

    class << self
      include Enumerable

      def drivers = Native::Camera.drivers

      def driver
        Subsystems.camera.start
        Native::Camera.current_driver
      end

      # Every camera SDL can see, as Devices.
      def all
        Subsystems.camera.start
        Native::Camera.ids.map { |id| Device.new(id: id, name: Native::Camera.name_for(id), position: position_of(id)) }
      end

      def each(&) = all.each(&)
      def first = all.first || None.new
      def any? = !all.empty?
      def find(id) = all.find { |device| device.id == id } || None.new

      # Opens the first camera; Camera::None when there is none.
      def open(size: nil, fps: nil) = first.open(size: size, fps: fps)

      def format_from(spec)
        width, height, numerator, denominator = spec
        Format.new(width: width, height: height, fps: Rational(numerator, denominator.nonzero? || 1).to_f)
      end

      private

      def position_of(id) = Native::Camera.position_for(id)&.to_sym || :unknown
    end

    attr_reader :native, :device

    def initialize(native, device:)
      @native = native
      @device = device
    end

    def id = device.id
    def name = device.name
    def position = device.position
    def none? = false

    # :pending until the user answers, then :approved or :denied.
    def permission = native.permission.to_sym
    def approved? = permission == :approved
    def denied? = permission == :denied
    def pending? = permission == :pending

    # The format frames arrive in; nil until approved.
    def format = native.format&.then { |spec| Camera.format_from(spec) }

    # The newest frame as a Surface of its own, or nil when none is ready.
    def frame = native.frame&.then { |surface| Surface.new(surface) }

    def close = tap { native.close }
    def inspect = "#<Rbgame::Camera #{id} #{name.inspect} (#{permission})>"

    # The camera that is not there: nothing to see, nothing to approve, so
    # `Camera.open` and `Camera.first` are always safe to use.
    class None
      def id = nil
      def name = "no camera"
      def position = :unknown
      def formats = []
      def open(size: nil, fps: nil) = self
      def none? = true
      def permission = :denied
      def approved? = false
      def denied? = true
      def pending? = false
      def format = nil
      def frame = nil
      def close = self
      def inspect = "#<Rbgame::Camera::None>"
    end
  end
end
