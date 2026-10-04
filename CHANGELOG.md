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
