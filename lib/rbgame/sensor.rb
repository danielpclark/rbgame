# frozen_string_literal: true

module Rbgame
  # The machine's own motion sensors (a tablet's accelerometer, a laptop's
  # gyroscope) through SDL's sensor API. Most desktops have none, so
  # `Sensor.first` is often `Sensor::None`; gamepads carry their own (see
  # `Gamepad#gyroscope`), which is where games usually find motion.
  #
  #   case Sensor.first
  #   in Sensor::None then steer_with_keys
  #   in sensor then tilt = sensor.reading   # => Reading(x, y, z) in m/s^2
  #   end
  #
  # Readings are as of the last `Events.pump`, like the keyboard's state.
  class Sensor
    # SDL's sensor types, in SDL's order.
    TYPES = %i[unknown accelerometer gyroscope accelerometer_left gyroscope_left accelerometer_right gyroscope_right].freeze
    GRAVITY = 9.80665

    # Three axes of a reading: m/s^2 for accelerometers (a device at rest
    # on a table reads roughly `[0, GRAVITY, 0]`), rad/s for gyroscopes.
    Reading = Data.define(:x, :y, :z) do
      def self.[](x, y, z) = new(x: x.to_f, y: y.to_f, z: z.to_f)
      def self.from(values) = self[*values.first(3)]
      def to_a = [x, y, z]
      def magnitude = Math.sqrt((x * x) + (y * y) + (z * z))
      def at_rest?(tolerance: 0.001) = magnitude < tolerance
      def to_s = format("(%.3f, %.3f, %.3f)", x, y, z)
    end
    Reading::ZERO = Reading[0, 0, 0]

    class << self
      include Enumerable

      # Every sensor the platform reports: the same object for as long as it
      # stays connected.
      def all
        Subsystems.sensor.start
        ids = Native::Sensor.ids
        registry.keep_if { |id, _| ids.include?(id) }
        ids.map { |id| registry[id] ||= new(Native::Sensor.open(id)) }
      end

      def each(&) = all.each(&)
      def first = all.first || None.new
      def any? = !all.empty?
      def find(id) = all.find { |sensor| sensor.id == id } || None.new
      def accelerometers = all.select(&:accelerometer?)
      def gyroscopes = all.select(&:gyroscope?)

      def type_index(type) = TYPES.index(type.to_sym) || raise(ArgumentError, "unknown sensor type #{type.inspect}")

      private

      def registry = @registry ||= {}
    end

    attr_reader :native

    def initialize(native)
      @native = native
    end

    def id = native.id
    def name = native.name || "sensor #{id}"
    def type = TYPES.fetch(native.type_index, :unknown)
    def accelerometer? = type.to_s.start_with?("accelerometer")
    def gyroscope? = type.to_s.start_with?("gyroscope")
    def none? = false

    # The latest three axes.
    def reading = Reading.from(native.data(3))

    # Up to SDL's 16 raw values, for sensors that report more than three.
    def values(count = 6) = native.data(count)

    def close
      native.close
      self
    end

    def inspect = "#<Rbgame::Sensor #{id} #{name.inspect} (#{type})>"

    # The sensor that is not there: it reads zero and has no type.
    class None
      def id = nil
      def name = "no sensor"
      def type = :none
      def accelerometer? = false
      def gyroscope? = false
      def none? = true
      def reading = Reading::ZERO
      def values(count = 6) = Array.new(count, 0.0)
      def close = self
      def inspect = "#<Rbgame::Sensor::None>"
    end
  end
end
