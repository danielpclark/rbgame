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

### Changed
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
