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

class Bounce < Rbgame::Game
  configure size: [640, 350], title: "Bounce", fps: 60

  def setup
    @pos = screen.center
    @vel = Rbgame::Vector.polar(30, 180)   # degrees, pixels per second
  end

  def update(dt)
    @pos += @vel * dt
    @vel = @vel.with(x: -@vel.x) unless (0..screen.width).cover?(@pos.x)
    @vel = @vel.with(y: -@vel.y) unless (0..screen.height).cover?(@pos.y)
  end

  def draw(screen)
    screen.fill(Rbgame::Color::EGA[1])
    screen.circle(@pos, 12, :yellow)
    screen.text("Esc to quit", at: [8, 8], color: :white)
  end

  def on_event(event)
    case event
    in Rbgame::Event::KeyDown[sym: :escape] then stop
    else super
    end
  end
end

Bounce.run
```

Or keep the loop yourself:

```ruby
Rbgame.run(size: [320, 200], title: "Hello") do |screen|
  clock = Rbgame::Clock.new
  loop do
    Rbgame::Events.each { |event| break if event in Rbgame::Event::Quit }
    screen.fill(:black).circle(screen.center, 40, "#ffff55")
    screen.present
    clock.tick(60)
  end
end
```

## Status

Early, and honest about it. The SDL translation has every platform-independent
part of SDL (surfaces, every blitter, the software renderer, the event core,
audio conversion) but **no platform video backend yet**: it cannot open a
window on your desktop today. rbgame therefore runs on SDL's `offscreen`
driver, draws into a framebuffer, and can read it back (`screen.to_surface`,
`screen.screenshot`). That is enough for the test suite, for recording a
game frame by frame, and for building a game that will show up on screen
the day the Wayland/X11/Windows/Cocoa backends land upstream, with no change
on this side. `docs/UPSTREAM.md` explains how rbgame follows that project.

## Installing

Requirements: Ruby 3.2–3.4 (built `--enable-shared`), a stable Rust toolchain
(1.87+), and nothing else: no SDL package, no C compiler.

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
| `Surface` | CPU pixels: `fill`, `fill_circle`, `[x, y]`, `blit`, `scaled`, `rotated`, `flipped`, `color_key=`, `save`/`Surface.load` (BMP) |
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
examples/       Gorillas
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
