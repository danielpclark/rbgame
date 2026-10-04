# frozen_string_literal: true

module Rbgame
  class Canvas
    # Textures: uploading, drawing and drawing into them.
    #
    #   tex = screen.texture(surface)
    #   screen.draw(tex, at: [10, 10])                   # natural size
    #   screen.draw(tex, rect: [10, 10, 64, 64])         # scaled into a rect
    #   screen.draw(tex, at: p, source: [0, 0, 16, 16])  # a sprite-sheet cell
    #   screen.draw(tex, at: p, angle: 90, flip: :horizontal)
    #   screen.draw(surface, at: p)                      # uploaded for this call
    module Images
      # Uploads a Surface for fast drawing.
      def texture(surface)
        Texture.new(renderer.create_texture_from_surface(surface.native), renderer)
      end

      # A blank texture this canvas can draw into with #with_target.
      def target_texture(size)
        size = Vector.coerce(size)
        Texture.new(renderer.create_target_texture(size.x.round, size.y.round), renderer)
      end

      # Draws an image: a Texture, or a Surface (uploaded for this call).
      def draw(image, at: nil, rect: nil, source: nil, angle: 0, center: nil, flip: :none, alpha: nil)
        image.with_texture(self) do |texture|
          texture.alpha = alpha if alpha
          Placement.new(texture, at: at, rect: rect, source: source, angle: angle, center: center, flip: flip)
                   .render(renderer)
        end
        self
      end

      # Draws into `texture` for the block, then back to the canvas.
      def with_target(texture)
        renderer.render_target = texture.native
        yield self
      ensure
        renderer.render_target = nil
      end

      # Where and how a texture lands on the canvas: the source cell, the
      # destination rectangle, and any turn or flip.
      class Placement
        attr_reader :texture, :source, :dest, :angle, :center, :flip

        def initialize(texture, at:, rect:, source:, angle:, center:, flip:)
          @texture = texture
          @source = source && Rect.coerce(source)
          @dest = rect ? Rect.coerce(rect) : Rect.at(at || Vector::ZERO, (@source || texture).size)
          @angle = angle.to_f
          @center = center && Vector.coerce(center)
          @flip = FLIP_MODES.code(flip)
        end

        def upright? = angle.zero? && flip == FLIP_MODES.code(:none)

        def render(renderer)
          if upright?
            renderer.render_texture(texture.native, *source_args, *dest.to_a)
          else
            # SDL turns clockwise; rbgame's angles are counter-clockwise.
            renderer.render_texture_rotated(texture.native, *source_args, *dest.to_a, -angle, center&.x, center&.y, flip)
          end
        end

        private

        def source_args = source ? source.to_a : [nil] * 4
      end
    end

    include Images
  end
end
