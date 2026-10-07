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

### Fixed
- `Events.each` (and so `Events.any?`, `to_a`, `grep`) yields everything
  queued: an `Events.wait` that returned an event left SDL's cycle-ending
  sentinel behind, and the next drain stopped at it before anything pushed
  since, such as the Quit in the README's loop.

### Changed
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
