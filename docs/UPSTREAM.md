# Tracking upstream

rbgame stands on two projects that move quickly, both by the same author:

| Dependency | What it is | Where it is pinned |
|---|---|---|
| [danielpclark/SDL](https://github.com/danielpclark/SDL) (`sdl3` crate) | SDL 3 translated to pure Rust, line by line | `Cargo.toml` (`rev = ...`) and `Cargo.lock` |
| [danielpclark/rutie](https://github.com/danielpclark/rutie) | The tie between Ruby and Rust; no hand-written FFI | `Cargo.toml` (`rutie = "0.13"`), `rbgame.gemspec` (`rutie` gem) |

## The SDL translation

The `sdl3` crate is a git dependency pinned to a commit, so every checkout of
rbgame builds the same SDL. The pin is deliberate: upstream lands new
subsystems and platform backends often, and a float would make builds
non-reproducible and break without a change on our side.

Keeping up is a two-command routine:

```sh
bundle exec rake sdl:check    # is the pin behind upstream HEAD?
bundle exec rake sdl:update   # move the pin to HEAD (or REV=<sha>), refresh Cargo.lock, rebuild
bundle exec rake              # then run every test before committing Cargo.toml + Cargo.lock
```

CI runs `sdl:check` weekly and on pull requests (advisory on PRs, failing on
the schedule), so a stale pin gets noticed.

### What to look for in an update

The translation's `README.md` and `docs/ROADMAP.md` list what is done. What
has arrived so far, and what rbgame did about it:

* **Platform video backends.** X11, Wayland (Linux) and Windows are
  translated. `Rbgame.init` lets SDL pick a driver when a real one exists and
  falls back to `offscreen` only when none can start (`VideoDriver.choose`
  and `Subsystems::Video`), so X11 and Wayland were picked up with no code
  change; CI runs the suites on X11 under Xvfb. Still to come: Cocoa, the
  mobile and console backends.
* **GPU renderers.** OpenGL, OpenGL ES 2.0, Vulkan and Direct3D 11 (Windows)
  are translated and come before `software` in SDL's list, so a window on a
  display now draws through the GPU (OpenGL on Mesa's llvmpipe under Xvfb in
  CI, where the suites pass pixel for pixel as they did in software).
  `Display.set_mode(driver: ...)` still passes a renderer name through, and
  `Display.renderers` lists them; headless `offscreen` windows keep the
  software renderer unless Mesa's EGL is installed.
* **Audio drivers.** ALSA, PulseAudio, PipeWire and WASAPI. `Mixer.default`
  opens the default device; with none it is `Mixer::Silence`.
* **Image codecs.** PNG and JPEG (stb_image and miniz translated), so
  `Surface.load` reads them and `Surface#save` writes PNG.
* **Input.** The HIDAPI gamepad drivers (Xbox, PlayStation, Nintendo, Steam
  and many more), Linux evdev, Windows GameInput/RawInput/WGI, the haptic
  drivers and the V4L2, PipeWire and Media Foundation camera drivers exist
  in the crate; rbgame has no gamepad or camera API yet. Keyboard and mouse
  arrive through the same event queue rbgame already drains, so they work
  on a display as they did headless.

Still worth watching:

* **Metal and the GPU renderer** for macOS, once the Cocoa backend lands.
* **SDL_ttf** for real fonts; `Canvas#text` uses SDL's 8x8 debug font until
  then.

### Where rbgame touches the crate

All of it is under `src/`, and it is small on purpose. `grep -n "sdl3::" src/*.rs`
lists every entry point used. If an update renames something, the compiler
says exactly where; the Ruby side (`lib/`) never sees SDL types.

## Rutie

Rutie tracks Ruby's C API per Ruby line (see its README table): 0.13 for Ruby
3.2–3.4, 0.14 for Ruby 4.0. `Cargo.toml` names the line; change it when you
change Ruby. The `rutie` *gem* (the loader) is version-independent.
