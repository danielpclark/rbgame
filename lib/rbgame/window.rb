# frozen_string_literal: true

module Rbgame
  # An operating-system window. Usually created for you by Display.set_mode.
  class Window
    FLAGS = {
      fullscreen: 0x1, hidden: 0x8, borderless: 0x10, resizable: 0x20, minimized: 0x40,
      maximized: 0x80, high_dpi: 0x2000, always_on_top: 0x10000, transparent: 0x40000000
    }.freeze

    attr_reader :native

    # Window.new(title: "Hello", size: [640, 480], resizable: true)
    def initialize(title: "rbgame", size: [640, 480], **flags)
      unknown = flags.keys - FLAGS.keys
      raise ArgumentError, "unknown window options: #{unknown.join(", ")}" unless unknown.empty?

      size = Vector.coerce(size)
      bits = flags.sum { |name, on| on ? FLAGS[name] : 0 }
      @native = Native.create_window(title.to_s, size.x.round, size.y.round, bits)
    end

    def id = native.id
    def title = native.title
    def title=(title)
      native.title = title.to_s
    end

    def size = Vector.new(*native.size)
    def width = size.x
    def height = size.y
    def bounds = Rect.new(0, 0, *native.size)
    def pixel_size = Vector.new(*native.size_in_pixels)

    def resize(size)
      size = Vector.coerce(size)
      native.resize(size.x.round, size.y.round)
      self
    end

    def position = Vector.new(*native.position)

    def move_to(position)
      position = Vector.coerce(position)
      native.move_to(position.x.round, position.y.round)
      self
    end

    def show = tap { native.show }
    def hide = tap { native.hide }
    def raise_to_front = tap { native.raise_window }

    def fullscreen=(on)
      native.fullscreen = on
    end

    def fullscreen? = flag?(:fullscreen)
    def resizable=(on)
      native.resizable = on
    end

    def bordered=(on)
      native.bordered = on
    end

    def minimum_size=(size)
      size = Vector.coerce(size)
      native.set_minimum_size(size.x.round, size.y.round)
    end

    def icon=(surface)
      native.icon = surface.native
    end

    def flag?(name) = (native.flags & FLAGS.fetch(name)) != 0
    def text_input=(on)
      on ? native.start_text_input : native.stop_text_input
    end

    def text_input? = native.text_input_active?
    def destroy = native.destroy
    def destroyed? = native.destroyed?
    def inspect = "#<Rbgame::Window #{title.inspect} #{size}>"
  end
end
