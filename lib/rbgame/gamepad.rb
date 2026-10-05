# frozen_string_literal: true

module Rbgame
  # A game controller as SDL maps it: one layout for every supported pad,
  # with positional names (`:south` is A on an Xbox pad and cross on a
  # PlayStation one), sticks as Vectors and triggers from 0 to 1.
  #
  #   pad = Gamepad.first             # Gamepad::None when nothing is plugged in
  #   pad.pressed?(:south)
  #   pad.left_stick                  # => Vector, dead zone applied
  #   pad.trigger(:right)             # => 0.0..1.0
  #   pad.rumble(0.5, seconds: 0.2)
  #
  #   Events.each do |event|
  #     case event
  #     in Event::GamepadButtonDown[button: :start] then pause
  #     in Event::GamepadAdded[gamepad:] then greet(gamepad)
  #     end
  #   end
  #
  # State is as of the last `Events.pump` (or poll), like the keyboard's.
  class Gamepad
    BUTTONS = %i[
      south east west north back guide start left_stick right_stick
      left_shoulder right_shoulder dpad_up dpad_down dpad_left dpad_right
      misc1 right_paddle1 left_paddle1 right_paddle2 left_paddle2 touchpad
      misc2 misc3 misc4 misc5 misc6
    ].freeze
    AXES = %i[left_x left_y right_x right_y left_trigger right_trigger].freeze
    AXIS_RANGE = 32_767.0
    DEAD_ZONE = 0.15

    class << self
      include Enumerable

      # Every connected gamepad: the same object for a pad for as long as it
      # stays plugged in.
      def all
        Subsystems.gamepad.start
        ids = Native::Gamepad.ids
        registry.keep_if { |id, _| ids.include?(id) }
        ids.map { |id| registry[id] ||= new(Native::Gamepad.open(id)) }
      end

      def each(&) = all.each(&)
      def first = all.first || None.new
      def any? = !all.empty?

      # The gamepad with SDL's id, or None once it is gone.
      def find(id) = all.find { |pad| pad.id == id } || None.new

      def button_index(button) = BUTTONS.index(button.to_sym) || raise(ArgumentError, "unknown gamepad button #{button.inspect}")
      def axis_index(axis) = AXES.index(axis.to_sym) || raise(ArgumentError, "unknown gamepad axis #{axis.inspect}")

      private

      def registry = @registry ||= {}
    end

    attr_reader :native
    attr_accessor :dead_zone

    def initialize(native, dead_zone: DEAD_ZONE)
      @native = native
      @dead_zone = dead_zone
    end

    def id = native.id
    def name = native.name || "gamepad #{id}"
    def type = native.type_name&.to_sym || :unknown
    def player = native.player_index
    def connected? = native.connected?
    def none? = false

    def pressed?(button) = native.button?(Gamepad.button_index(button))
    def pressed = BUTTONS.select { |button| pressed?(button) }
    def button?(button) = native.has_button?(Gamepad.button_index(button))
    def axis?(axis) = native.has_axis?(Gamepad.axis_index(axis))

    # -1.0..1.0 for sticks, 0.0..1.0 for triggers.
    def axis(axis) = (native.axis(Gamepad.axis_index(axis)) / AXIS_RANGE).clamp(-1.0, 1.0)

    def left_stick = stick(:left_x, :left_y)
    def right_stick = stick(:right_x, :right_y)
    def trigger(side) = axis(:"#{side}_trigger").clamp(0.0, 1.0)

    # Strengths from 0 to 1. False when this pad cannot rumble.
    def rumble(low, high = low, seconds: 0.25) = native.rumble(strength(low), strength(high), millis(seconds))
    def rumble_triggers(left, right = left, seconds: 0.25) = native.rumble_triggers(strength(left), strength(right), millis(seconds))

    # False when this pad has no light.
    def led=(color)
      color = Color.coerce(color)
      native.set_led(color.r, color.g, color.b)
    end

    def close
      native.close
      self
    end

    def inspect = "#<Rbgame::Gamepad #{id} #{name.inspect} (#{type})>"

    private

    def stick(x_axis, y_axis)
      vector = Vector.new(axis(x_axis), axis(y_axis))
      vector.magnitude < dead_zone ? Vector::ZERO : vector
    end

    def strength(fraction) = (fraction.clamp(0.0, 1.0) * 0xFFFF).round
    def millis(seconds) = (seconds * 1000).round

    # The gamepad that is not there: every reading is at rest, every command
    # a no-op, so `Gamepad.first` is always safe to use.
    class None
      def id = nil
      def name = "no gamepad"
      def type = :none
      def player = -1
      def connected? = false
      def none? = true
      def pressed?(_button) = false
      def pressed = []
      def button?(_button) = false
      def axis?(_axis) = false
      def axis(_axis) = 0.0
      def left_stick = Vector::ZERO
      def right_stick = Vector::ZERO
      def trigger(_side) = 0.0
      def rumble(_low, _high = nil, seconds: nil) = false
      def rumble_triggers(_left, _right = nil, seconds: nil) = false
      def led=(_color)
        false
      end
      def close = self
      def inspect = "#<Rbgame::Gamepad::None>"
    end

    # A pretend gamepad SDL treats like a real one, for tests and demos:
    #
    #   pad = Gamepad::Virtual.attach(name: "Test pad")
    #   pad.press(:south)
    #   pad.move(:left_x, -1.0)
    #   Events.pump                   # now pad.gamepad reads the new state
    #   pad.detach
    #
    # It has the fifteen standard buttons (`:south` to `:dpad_right`) and
    # the six axes, and is already open (`gamepad`), so its events arrive.
    class Virtual
      TRIGGERS = %i[left_trigger right_trigger].freeze

      def self.attach(name: "Virtual gamepad")
        Subsystems.gamepad.start
        new(Native::VirtualGamepad.attach(name)).at_rest
      end

      attr_reader :native, :gamepad

      def initialize(native)
        @native = native
        @gamepad = Gamepad.find(native.id)
      end

      def id = native.id

      def press(button) = tap { native.set_button(Gamepad.button_index(button), true) }
      def release(button) = tap { native.set_button(Gamepad.button_index(button), false) }

      # `value` from -1 to 1 for sticks, 0 to 1 for triggers.
      def move(axis, value)
        axis = axis.to_sym
        value = TRIGGERS.include?(axis) ? (value.clamp(0.0, 1.0) * 2) - 1 : value.clamp(-1.0, 1.0)
        tap { native.set_axis(Gamepad.axis_index(axis), (value * AXIS_RANGE).round) }
      end

      # Sticks centred, triggers and buttons released.
      def at_rest
        AXES.each { |axis| move(axis, 0.0) }
        BUTTONS.first(15).each { |button| release(button) }
        self
      end

      def detach = tap { native.detach }
    end
  end
end
