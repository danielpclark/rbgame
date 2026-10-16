# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- The gem: `Rbgame.init`/`run`, `Display`, `Screen`/`Canvas` drawing (fills,
  strokes, circles, ellipses, arcs, polygons, thick lines, text, textures,
  render targets, clipping, logical resolution), `Surface` pixel work and
  BMP I/O, `Texture`, `Window`, `Events`/`Event` as pattern-matchable `Data`
  classes, `Key`/`Mouse` state, `Clock`, `Color`/`Vector`/`Rect` value
  objects, `Sound`/`Mixer` playback and `Synth`, a QBasic `PLAY` interpreter.
- `Rbgame::Game`, a subclassable frame loop with frame limits and frame
  recording for headless runs.
- The Rust extension (`src/`) over the pure-Rust SDL 3 translation, loaded
  through Rutie; no C and no hand-written FFI.
- Gorillas (`examples/gorillas`): a clone of QBasic's GORILLA.BAS, playable
  and self-playing, with the original tunes.
- `rake sdl:check` / `rake sdl:update` to follow the SDL translation.
- `Rbgame::Gamepad`: SDL's gamepad layer with named buttons (`:south`,
  `:dpad_left`, ...) and axes, sticks as `Vector`s with a dead zone,
  triggers from 0 to 1, rumble and LED, `Gamepad.first` with
  `Gamepad::None` when nothing is plugged in; `Event::GamepadAdded`,
  `GamepadRemoved`, `GamepadButtonDown`/`Up` and `GamepadAxisMotion`;
  `Gamepad::Virtual`, a pretend pad for tests and demos.

- `Rbgame::Power`: `Power.status` with the state (`:on_battery`,
  `:charging`, `:charged`, `:no_battery`, `:unknown`), seconds and percent
  left, and `low?`, `on_battery?`, `plugged_in?`.
- `Rbgame::Locale`: `Locale.preferred`, `Locale.first` and
  `Locale.pick(available)` for choosing a game's language.
- `Rbgame::Sensor`: the machine's accelerometers and gyroscopes with
  `Sensor::Reading` values, `Sensor::None` when there are none, and
  `Event::SensorUpdate`; `Gamepad#enable(:gyroscope)`, `#gyroscope`,
  `#accelerometer`, `#sensors` and `Event::GamepadSensor` for pads with
  motion sensors, and `Gamepad::Virtual#tilt` to fake them.

### Fixed
- `bin/setup` and a plain `cargo build` link on macOS: a build script
  leaves the `rb_*` symbols to the loader (`-undefined dynamic_lookup`),
  as `rake rutie:build` did, instead of failing with undefined symbols.
- `Events.each` (and so `Events.any?`, `to_a`, `grep`) yields everything
  queued: an `Events.wait` that returned an event left SDL's cycle-ending
  sentinel behind, and the next drain stopped at it before anything pushed
  since, such as the Quit in the README's loop.

### Changed
- Gorillas looks like the original: the field is shown at 4:3 as an EGA
  monitor showed it, the gorillas are DrawGorilla's (boxes, brow, nose,
  arcs for legs, chest and arms, five pixels thick), the sun is DoSun's
  (disc, eight rays, smile or O), the banana is a tapered crescent, and
  the explosion and its crater are round on the stretched field. The city
  is built as MakeCityScape built it: widths of 38 to 74, a slope (rising,
  falling, valley three times in six, peak) whose trend every building
  adds a fresh roll of up to 120 to, so no city is a flat row. The wind
  is rolled the original way (-4 to 5 with a one-in-three gust of up to
  10 more, so sometimes calm) and again for every throw; its arrow is six
  pixels per unit, under the score.
- The native layer is written in Rutie 0.13.3's `derive` style: every
  `Rbgame::Native` class is a `#[rubyclass]` struct with `#[rubymethods]`,
  the module's functions are `#[rubymodule]` blocks, and errors are returned
  (and raised once the method's values are dropped) instead of thrown past
  them. Same Ruby API; `lazy_static` is no longer a dependency.
- `Mixer` plays on SDL_mixer's tracks: `play` starts a `Channel` of its own
  (`volume:`, `pan:`, `loops:`, `fade_in:`), so sounds overlap instead of
  queueing; `Channel#stop(fade_out:)`, `pause`, `resume`, `volume=`, `pan=`;
  `Mixer#channels`, `Mixer.offline(rate:, channels:)` with `render(seconds)`
  for mixing into a `Sound`. `Mixer.new(output:)` and `Mixer#queued` are
  gone; `Mixer::Silence` stands in for the whole mixer without a device.
- SDL translation updated to `f58aa51c` (49 upstream commits): the macOS
  port. The Cocoa video driver (OpenGL, Metal views, Vulkan through
  MoltenVK), the Metal renderer and the GPU API's Metal backend, the
  CoreAudio driver, the IOKit, MFi and HIDAPI controller drivers with
  ForceFeedback haptics, the CoreMedia camera driver, and the macOS power,
  locale, URL and filesystem backends, so rbgame opens a real window on a
  Mac and CI runs the suites on it; also Cocoa file dialogs, tray and
  notifications, which rbgame does not wrap.
- SDL translation updated to `f261c1b6` (21 upstream commits): the Linux
  and Windows power backends, the Unix and Windows time, timer, locale,
  URL and filesystem backends, the Windows process, dialog, notification,
  tray and sensor backends, and renderer work (wrapped GL, Vulkan and
  Direct3D textures and objects, OpenGL ES 3 shaders, GPU renderers
  without a window) that changes nothing rbgame draws.
- SDL translation updated to `58cc3d9b` (21 upstream commits): APNG
  decoding and encoding (libpng and zlib translated) in `sdl3-image`, so
  `Animation.load` and `save` handle `.png`/`.apng` losslessly; in
  `sdl3-ttf`, FreeType's Type 1, CID, Type 42, PFR, Windows FNT, PCF and
  BDF drivers, HarfBuzz's AAT shaping and FreeType's OT-SVG renderer with
  PlutoSVG, so `Font.load` reads those formats and renders OpenType SVG
  glyphs in colour; the Direct3D 12 renderer (Windows, after Direct3D 11
  in SDL's list).
- SDL translation updated to `5c1c24fb` (20 upstream commits): AVIF images
  and image sequences (libavif over dav1d) and JPEG XL (libjxl) decoding in
  `sdl3-image`, so `Surface.load` reads `.avif` and `.jxl` and
  `Animation.load` reads `.avifs`; the `sdl3-shadercross` crate (SPIR-V
  reflection and cross-compilation for SDL's GPU API), which rbgame does
  not wrap.
- SDL translation updated to `47c817cc` (51 upstream commits): the
  `sdl3-ttf` crate (SDL_ttf with FreeType and HarfBuzz translated), which
  `Font` now uses; WebP encoding, TIFF decoding and dav1d's AV1 decoder in
  `sdl3-image`; the `sdl3-rtf` crate, which rbgame does not wrap.
- SDL translation updated to `cc374012` (27 upstream commits): the
  `sdl3-mixer` crate (SDL_mixer translated: the mixer and its WAV, AIFF,
  VOC, AU, MP3, Ogg Vorbis and FLAC decoders, plus TiMidity for MIDI in
  its own crate), which `Music` and `Sound.load` now use; WebP decoding in
  `sdl3-image`; the `sdl3-net` crate, which rbgame leaves to Ruby's
  `socket`.
- SDL translation updated to `50de5cb9` (39 upstream commits): the
  `sdl3-image` crate (SDL_image translated: the decoders, savers,
  animations, SVG through nanosvg), which `Surface` and `Animation` now
  use; the GPU renderer with Vulkan and Direct3D 12 backends (after
  OpenGL in SDL's list, so nothing changes on a display); the `sdl3-test`
  crate for upstream's own tests.
- SDL translation updated to `67182975` (2 upstream commits): the GPU API
  front end, which rbgame does not use (the 2D renderer is its drawing
  model).
- SDL translation updated to `d4e95a8c` (40 upstream commits): the Wayland
  video driver; the OpenGL, OpenGL ES 2.0, Vulkan and Direct3D 11 renderers,
  which SDL now prefers over `software` on a window with a display
  (`Display.renderers` lists them, `Display.set_mode(driver: "software")`
  opts out); HIDAPI gamepad drivers, haptics, GameInput and camera drivers
  in the crate.
- SDL translation updated to `dc9c4a48` (90 upstream commits): the X11 and
  Windows video drivers, so rbgame opens a real window on X11 (the suites run
  on it under Xvfb in CI); ALSA, PulseAudio, PipeWire and WASAPI audio
  drivers; PNG and JPEG codecs, exposed as `Surface.load` (PNG, JPEG, BMP)
  and `Surface#save` (PNG, or BMP by extension); Linux and Windows joystick
  drivers in the crate.
- The library restructured around objects: `Mixer` is an instance given its
  output (`Mixer::Silence` when there is none; `Mixer.default` keeps the old
  class-level API), `Game` records frames through a `FrameRecorder`,
  `Canvas#draw` takes anything with `with_texture` (Surface and Texture), named
  SDL modes resolve through `Rbgame::Mode` (`BLEND_MODES`, `SCALE_MODES`,
  `FLIP_MODES`, `PRESENTATION_MODES`), `Canvas` is split into `Shapes`, `Text`
  and `Images` concerns, `Synth` into a `Score`, a `SquareWave` and a lazy
  sample stream, `Rbgame.init` into `Subsystems` with the driver choice in
  `VideoDriver.choose`, and key state moves to `Keyboard` (`Key.pressed?` stays).
- RBS signatures for the public API in `sig/`, validated by `rake rbs:validate`
  and CI.
- Gorillas restructured around objects: `Round` delegates to phase objects
  (`Aiming`, `Flying`, `Exploding`, `Dancing`, `Over`), input goes through a
  `Questionnaire` answered by a `Keyboard` or an `Autopilot` controller, the
  `Jukebox` listens to the round instead of being called from it, sprites and
  views draw the model instead of the model drawing itself, and the skyline is
  built by an `Architect` under a `Slope` strategy.
