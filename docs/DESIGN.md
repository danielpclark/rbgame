# Design notes

## Two layers, one rule

```
 your game  ──►  lib/rbgame/*.rb  (the API: Ruby all the way)
                       │
                       ▼
                 Rbgame::Native   (src/*.rs: thin, primitive arguments, raises Rbgame::SDLError)
                       │ rutie
                       ▼
                 sdl3 crate       (SDL 3, translated to Rust; no C, no FFI)
```

The rule: **Rust only does what must touch SDL.** Everything a Ruby
programmer sees is designed in Ruby, where keyword arguments, blocks, `Data`,
`Comparable`, `Enumerable` and pattern matching exist. The Rust side never
takes a Ruby Hash, never yields a block, and never defines a Ruby-visible
class with behaviour beyond holding a handle. That keeps the native layer
small (and easy to re-check when the SDL translation moves), and keeps the
API's shape a matter of Ruby code, where it belongs.

So `Rbgame::Native.create_window(title, w, h, flags)` exists, and
`Rbgame::Window.new(title:, size:, resizable: true)` is written in Ruby on
top of it. `Native::Renderer#geometry(texture, flat_floats, indices)` exists,
and `Canvas#polygon(points, color)` triangulates in Ruby and calls it.

## Values are values

`Color`, `Vector`, `Rect`, every `Event`, `Shot` in the demo: all `Data`
classes, immutable, equal by value, usable as Hash keys, pattern-matchable.
pygame's `Rect` mutates (`rect.x += 1`); ours returns a new one
(`rect.move(1, 0)`), so rectangles can be shared without surprises.

Every method that takes a colour, point or rect takes *anything that can be
coerced* to one: `:red`, `"#ff0000"`, `[255, 0, 0]`, a `Color`. Coercion lives
in one place per type (`Color.coerce`, `Vector.coerce`, `Rect.coerce`).

## Resources are objects with a clear owner

Windows, renderers, surfaces, textures and audio streams are Rust values
wrapped in Ruby objects (`wrappable_struct!`). Ruby's GC frees them; `destroy`
frees them early. A `Texture` belongs to the `Canvas` that made it. Handles
are checked by SDL on every use, so a stale one raises instead of crashing.

## Errors are exceptions, and they have a family

`Rbgame::Error` is the root. `SDLError` carries SDL's own message.
`StateError` is "wrong order" (a destroyed window, no display yet).
`NativeLoadError` says how to build the extension. Argument problems are
plain `ArgumentError`/`TypeError`, as Ruby expects.

## The loop is yours, or ours

pygame hands you a loop to write. rbgame does that too (`Events.each`,
`Clock#tick`, `screen.present`), and also offers `Rbgame::Game`: a class with
`setup`/`update(dt)`/`draw(screen)`/`on_event(event)` hooks and a `run` that
can stop after N frames or save every frame, which is how the demo and the
tests run without a window.

## Headless by default when there is no head

The SDL translation has no platform video backend yet. `Rbgame.init` notices
when only `dummy`/`offscreen` drivers exist and chooses `offscreen`, so every
example runs, draws into a framebuffer and can be read back (`to_surface`,
`screenshot`). Tests pin the driver through `RBGAME_VIDEO_DRIVER` so they run
the same on a developer's desktop and in CI.

## The demo is the proof

`examples/gorillas` keeps its model (`Skyline`, `Terrain`, `Shot`, `Round`,
`Match`, `Autoplayer`) free of drawing and input, with scenes on top. The
model has its own tests; the game is playable, and plays itself for
recordings.
