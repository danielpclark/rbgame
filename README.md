# rbgame

**Games in Ruby, on SDL, with no C anywhere in the stack.**

rbgame is to Ruby what [pygame](https://www.pygame.org) is to Python: windows,
drawing, images, events, timing and sound for 2D games. Two things make it
unusual:

* **SDL itself is Rust.** rbgame runs on
  [danielpclark/SDL](https://github.com/danielpclark/SDL), a line-by-line
  translation of SDL 3 into pure Rust. No C is compiled, vendored or linked.
* **No FFI is written by hand.** Ruby reaches that Rust through
  [Rutie](https://github.com/danielpclark/rutie), so the native layer is a few
  hundred lines of Rust methods, not a binding generator's output.

And one thing makes it Ruby: the API is designed as a Ruby library, not a
transliteration of pygame. Value objects are immutable `Data` classes that
pattern match, colours and points coerce from whatever you have, drawing
methods take keyword arguments, the event queue is `Enumerable`, and there is
a `Game` class to subclass when you would rather not write the loop.

```ruby
require "rbgame"

module Bounce
  # Where the ball is and where it is going. Moving it returns a new ball.
  class Ball < Data.define(:center, :velocity, :radius)
    include Rbgame

    def after(seconds, within:)
      with(center: center + (velocity * seconds)).rebounding_off(within)
    end

    def draw_on(canvas) = canvas.circle(center, radius, :yellow)

    # A ball past an edge turns around on that axis.
    def rebounding_off(box)
      across = (box.left + radius)..(box.right - radius)
      down = (box.top + radius)..(box.bottom - radius)
      with(velocity: Vector.new(across.cover?(center.x) ? velocity.x : -velocity.x,
                                down.cover?(center.y) ? velocity.y : -velocity.y))
    end
  end

  class Game < Rbgame::Game
    include Rbgame

    configure size: [640, 350], title: "Bounce", fps: 60

    def setup
      @ball = Ball.new(center: screen.center, velocity: Vector.polar(30, 180), radius: 12)
    end

    def update(seconds) = @ball = @ball.after(seconds, within: screen.bounds)

    def draw(screen)
      screen.fill(Color::EGA[1])
      @ball.draw_on(screen)
      screen.text("Esc to quit", at: [8, 8])
    end

    def on_event(event)
      case event
      in Event::KeyDown[sym: :escape] then stop
      else super
      end
    end
  end
end

Bounce::Game.run
```

That is `examples/bounce.rb`, and the test suite runs it. `include Rbgame`
brings `Vector`, `Color`, `Event` and friends into a class's scope, as
`include Math` does for `PI`; the ball is a value that knows how to move
itself; the game only wires hooks to it.

Or keep the loop yourself:

```ruby
Rbgame.run(size: [320, 200], title: "Hello") do |screen|
  clock = Rbgame::Clock.new
  until Rbgame::Events.any?(Rbgame::Event::Quit)
    screen.fill(:black).circle(screen.center, 40, :yellow).present
    clock.tick(60)
  end
end
```

`Events` is `Enumerable` over whatever has arrived, so `any?(Event::Quit)`
drains the queue and answers the only question this loop has. Drawing calls
return the canvas, so a frame is one chain ending in `present`.

## Status

Early, and honest about it. The SDL translation now has its first platform
backends, and rbgame uses them as they land:

* **Windows on screen**: the X11 and Wayland drivers (Linux) and the Windows
  driver are translated. On X11, rbgame opens a real window; the test suite
  runs on it under Xvfb in CI, so what works headless is also checked on a
  display. Wayland and Windows have not been tried by this project yet. macOS
  is still to come upstream; on a machine without a usable driver rbgame
  falls back to SDL's `offscreen` driver, draws into a framebuffer, and can
  read it back (`screen.to_surface`, `screen.screenshot`), which is how the
  rest of the tests and the Gorillas recorder run.
* **Drawing**: SDL's OpenGL, OpenGL ES 2.0, Vulkan and Direct3D 11 renderers
  are translated, and SDL picks the first that works on the window (OpenGL
  on X11 with Mesa, which is what CI runs on). `Display.set_mode(driver:
  "software")` asks for the software renderer instead; `Display.renderers`
  lists the choices.
* **Sound**: ALSA, PulseAudio, PipeWire and WASAPI drivers are translated.
  With no device, `Mixer` is silent rather than broken.
* **Images**: `Surface.load` reads PNG, JPEG and BMP; `Surface#save` writes
  PNG (or BMP by extension).
* **Still missing upstream**: fonts beyond SDL's 8x8 debug font, and the
  macOS backends. Gamepads (HIDAPI, evdev and Windows drivers) and cameras
  are in the crate but not yet in rbgame's API.

`docs/UPSTREAM.md` explains how rbgame follows that project.

## Installing

Requirements: Ruby 3.2–3.4 (built `--enable-shared`), a stable Rust toolchain
(1.87+), and nothing else: no SDL package, no C compiler. On Linux, SDL loads
the system's X11 and audio client libraries at run time if they are there
(`libX11`, `libasound`, `libpulse`, `libpipewire`), exactly as the C SDL does.

```sh
git clone https://github.com/danielpclark/rbgame
cd rbgame
bin/setup                 # bundle install && cargo build --release
bundle exec rake          # the tests, headless
bundle exec rake gorillas:play
```

Ruby 4.0 users: change `rutie = "0.13"` to `"0.14"` in `Cargo.toml` (Rutie
tracks one Ruby line per release).

## The demo: Gorillas

`examples/gorillas` is QBasic's GORILLA.BAS (1990) written again in Ruby:
two gorillas on a random skyline, exploding bananas, wind, craters, a sun
that is shocked when you hit it, and the original tunes played through
`Rbgame::Synth`, a `PLAY`-string interpreter, as PC-speaker square waves.
Ironically for a QBasic program, it draws to an SDL window and not a text
mode screen.

```sh
bundle exec rake gorillas:play                       # two players at one keyboard
examples/gorillas/bin/gorillas --autoplay            # the gorillas aim for themselves
examples/gorillas/bin/gorillas --autoplay --record frames/ --frames 600 --every 2
```

The game's model (`Skyline`, `Terrain`, `Shot`, `Round`, `Match`,
`Autoplayer`) knows nothing about pixels or keys and has its own tests;
scenes draw it and feed it input. Read it as a worked example of the API.

## A tour of the API

| | |
|---|---|
| `Rbgame.init`, `Rbgame.run`, `Rbgame.quit` | subsystems; `headless?`, `sdl_version` |
| `Display.set_mode(size, title:, logical:)` → `Screen` | the window's canvas; `present`, `screenshot` |
| `Canvas` | `fill`, `fill_rect`, `stroke_rect`, `line` (any width), `lines`, `circle`, `ellipse`, `arc`, `polygon` (concave too), `text`, `draw(texture, at:/rect:, angle:, flip:)`, `clip { }`, `with_target(texture) { }`, `to_surface` |
| `Surface` | CPU pixels: `fill`, `fill_circle`, `[x, y]`, `blit`, `scaled`, `rotated`, `flipped`, `color_key=`, `save`/`Surface.load` (PNG, JPEG, BMP) |
| `Texture` | a `Surface` uploaded for fast drawing; `alpha=`, `color_mod=`, `blend_mode=` |
| `Events` | `each`, `poll`, `wait(timeout:)`, `push_quit`; `Event::KeyDown`, `MouseDown`, `Window`, ... are `Data` |
| `Key`, `Keyboard`, `Mouse` | `Key.code(:space)`, `Keyboard.pressed?(:left)`, `Mouse.position` |
| `Clock` | `tick(fps)` → seconds, `fps`, `Clock.now`, `Clock.sleep` |
| `Color`, `Vector`, `Rect` | immutable values with the geometry you expect; `Color::EGA[14]` for the palette QBasic had |
| `Sound`, `Mixer`, `Synth` | WAV or sample playback (`Mixer.default`, or your own with any output); `Synth.play("T160 O1 L8 CDEDCD L4 ECC")` |
| `Game` | `setup`/`update(dt)`/`draw(screen)`/`on_event`; `run(frames:, screenshots:)` |

Everything that takes a colour accepts `Color`, `:red`, `"#ff0000"`,
`[255, 0, 0]`; everything that takes a point accepts `Vector` or `[x, y]`;
everything that takes a rect accepts `Rect` or `[x, y, w, h]`.

## Layout

```
src/            the Rust extension: Rbgame::Native, thin and primitive
lib/rbgame/     the Ruby API
examples/       bounce.rb (the README program) and Gorillas
test/           minitest, headless
sig/            RBS type signatures for the public API
docs/           DESIGN.md (why it looks like this), UPSTREAM.md (following SDL)
```

`docs/DESIGN.md` has the principles; the short version is *Rust only does
what must touch SDL, Ruby does the design*.

## License

Licensed under either of the MIT license ([LICENSE-MIT](LICENSE-MIT)) or the
Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE)), at your
option. The SDL translation it builds on is zlib-licensed, like SDL.
