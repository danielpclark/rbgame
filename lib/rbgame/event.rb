# frozen_string_literal: true

module Rbgame
  # Immutable event objects, one class per kind, built from the Hashes the
  # extension hands back. They are Data objects, so they pattern match:
  #
  #   case event
  #   in Event::Quit then stop
  #   in Event::KeyDown[sym: :escape] then stop
  #   in Event::KeyDown[sym:, repeat: false] then press(sym)
  #   in Event::MouseDown[button: :left, pos:] then click(pos)
  #   end
  module Event
    # Shared by key events.
    module Keyish
      def sym = Key.sym(key)
      def key?(name) = sym == name.to_sym || key == Key.code(name)
      def char = key.between?(32, 126) ? key.chr : nil
      def shift? = Key::Mod.shift?(modifiers)
      def ctrl? = Key::Mod.ctrl?(modifiers)
      def alt? = Key::Mod.alt?(modifiers)
      def repeat? = repeat

      def deconstruct_keys(keys)
        super(nil).merge(sym: sym, char: char)
      end
    end

    module Positioned
      def pos = Vector.new(x, y)
    end

    Quit = Data.define(:timestamp_ns)

    KeyDown = Data.define(:timestamp_ns, :window_id, :key, :scancode, :name, :modifiers, :repeat) { include Keyish }
    KeyUp = Data.define(:timestamp_ns, :window_id, :key, :scancode, :name, :modifiers, :repeat) { include Keyish }

    TextInput = Data.define(:timestamp_ns, :window_id, :text)
    TextEditing = Data.define(:timestamp_ns, :window_id, :text, :start, :length)

    MouseMotion = Data.define(:timestamp_ns, :window_id, :x, :y, :xrel, :yrel, :buttons) do
      include Positioned
      def rel = Vector.new(xrel, yrel)
      def pressed?(button) = (buttons & (1 << (Mouse::BUTTONS.fetch(button) - 1))) != 0
    end

    module Buttonish
      include Positioned
      def button = Mouse.button_name(button_number)
      def left? = button_number == 1
      def middle? = button_number == 2
      def right? = button_number == 3
      def double_click? = clicks >= 2

      def deconstruct_keys(keys)
        super(nil).merge(button: button, pos: pos)
      end
    end

    MouseDown = Data.define(:timestamp_ns, :window_id, :x, :y, :button_number, :clicks) { include Buttonish }
    MouseUp = Data.define(:timestamp_ns, :window_id, :x, :y, :button_number, :clicks) { include Buttonish }

    MouseWheel = Data.define(:timestamp_ns, :window_id, :x, :y, :mouse_x, :mouse_y) do
      def pos = Vector.new(mouse_x, mouse_y)
      def scroll = Vector.new(x, y)
    end

    Window = Data.define(:timestamp_ns, :window_id, :event, :data1, :data2) do
      def resized? = event == :resized || event == :pixel_size_changed
      def close_requested? = event == :close_requested
      def focus_gained? = event == :focus_gained
      def focus_lost? = event == :focus_lost
      def size = Vector.new(data1, data2)
    end

    Drop = Data.define(:timestamp_ns, :window_id, :x, :y, :data) { include Positioned }

    # Shared by gamepad events: `which` is SDL's id for the pad.
    module Gamepadish
      def gamepad = Gamepad.find(which)

      def deconstruct_keys(keys)
        super(nil).merge(gamepad: gamepad)
      end
    end

    module GamepadButtonish
      include Gamepadish
      def button = Gamepad::BUTTONS[button_number]
      def button?(name) = button == name.to_sym

      def deconstruct_keys(keys)
        super.merge(button: button)
      end
    end

    GamepadAdded = Data.define(:timestamp_ns, :which) { include Gamepadish }
    GamepadRemoved = Data.define(:timestamp_ns, :which) { include Gamepadish }
    GamepadButtonDown = Data.define(:timestamp_ns, :which, :button_number) { include GamepadButtonish }
    GamepadButtonUp = Data.define(:timestamp_ns, :which, :button_number) { include GamepadButtonish }

    # Shared by camera events: `which` is SDL's id for the device.
    module Cameraish
      def camera = Camera.find(which)

      def deconstruct_keys(keys)
        super(nil).merge(camera: camera)
      end
    end

    CameraAdded = Data.define(:timestamp_ns, :which) { include Cameraish }
    CameraRemoved = Data.define(:timestamp_ns, :which) { include Cameraish }
    CameraApproved = Data.define(:timestamp_ns, :which) { include Cameraish }
    CameraDenied = Data.define(:timestamp_ns, :which) { include Cameraish }

    ClipboardUpdate = Data.define(:timestamp_ns, :owner, :mime_types) do
      def owner? = owner
    end

    # Touch events: positions and movement are fractions of the window,
    # 0 to 1, so a finger's `pos` scales by the screen size.
    module Fingerish
      include Positioned
      def rel = Vector.new(dx, dy)

      def deconstruct_keys(keys)
        super(nil).merge(pos: pos)
      end
    end

    FINGER_FIELDS = %i[timestamp_ns window_id touch_id finger_id x y dx dy pressure].freeze
    FingerDown = Data.define(*FINGER_FIELDS) { include Fingerish }
    FingerUp = Data.define(*FINGER_FIELDS) { include Fingerish }
    FingerMotion = Data.define(*FINGER_FIELDS) { include Fingerish }
    FingerCanceled = Data.define(*FINGER_FIELDS) { include Fingerish }

    GamepadAxisMotion = Data.define(:timestamp_ns, :which, :axis_number, :raw_value) do
      include Gamepadish
      def axis = Gamepad::AXES[axis_number]
      def value = (raw_value / Gamepad::AXIS_RANGE).clamp(-1.0, 1.0)

      def deconstruct_keys(keys)
        super.merge(axis: axis, value: value)
      end
    end
    User = Data.define(:timestamp_ns, :window_id, :code)
    Unknown = Data.define(:timestamp_ns, :window_id, :raw_type, :description)

    CLASSES = {
      quit: Quit, key_down: KeyDown, key_up: KeyUp, text_input: TextInput, text_editing: TextEditing,
      mouse_motion: MouseMotion, mouse_down: MouseDown, mouse_up: MouseUp, mouse_wheel: MouseWheel,
      window: Window, drop: Drop, user: User,
      gamepad_added: GamepadAdded, gamepad_removed: GamepadRemoved,
      gamepad_button_down: GamepadButtonDown, gamepad_button_up: GamepadButtonUp,
      gamepad_axis_motion: GamepadAxisMotion,
      camera_added: CameraAdded, camera_removed: CameraRemoved,
      camera_approved: CameraApproved, camera_denied: CameraDenied,
      clipboard_update: ClipboardUpdate,
      finger_down: FingerDown, finger_up: FingerUp, finger_motion: FingerMotion, finger_canceled: FingerCanceled,
      other: Unknown
    }.freeze

    RENAMED_FIELDS = { button: :button_number, axis: :axis_number }.freeze

    class << self
      # The Event for a Hash from Rbgame::Native.
      def from_hash(hash)
        klass = CLASSES.fetch(hash[:type], Unknown)
        attributes = klass.members.to_h do |member|
          source = RENAMED_FIELDS.key(member) || member
          [member, hash.fetch(source) { default_for(member) }]
        end
        klass.new(**attributes)
      end

      private

      def default_for(member)
        case member
        when :window_id then nil
        when :raw_type then 0
        when :description then "unknown event"
        else nil
        end
      end
    end
  end
end
