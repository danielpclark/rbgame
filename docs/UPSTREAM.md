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

* **Platform video backends.** X11, Wayland (Linux), Windows and Cocoa
  (macOS, with OpenGL, Metal views and Vulkan through MoltenVK) are
  translated. `Rbgame.init` lets SDL pick a driver when a real one exists and
  falls back to `offscreen` only when none can start (`VideoDriver.choose`
  and `Subsystems::Video`), so X11, Wayland and Cocoa were picked up with
  no code change; CI runs the suites on X11 under Xvfb and on the Cocoa
  driver on the macOS runner (the job prints which driver and renderer SDL
  picked). Still to come: the mobile and console backends.
* **GPU renderers.** OpenGL, OpenGL ES 2.0, Vulkan, Direct3D 11 and 12
  (Windows) and Metal (macOS, first in SDL's list there) are translated and
  come before `software` in SDL's list, so a window on a display now draws
  through the GPU (OpenGL on Mesa's llvmpipe under Xvfb in CI, Metal on the
  macOS runner, where the suites pass pixel for pixel as they did in
  software).
  `Display.set_mode(driver: ...)` still passes a renderer name through, and
  `Display.renderers` lists them; headless `offscreen` windows keep the
  software renderer unless Mesa's EGL is installed.
* **Audio drivers.** ALSA, PulseAudio, PipeWire, WASAPI and CoreAudio.
  `Mixer.default` opens the default device; with none it is
  `Mixer::Silence`.
* **SDL_mixer.** `sdl3-mixer` (pinned with the others) decodes WAV, AIFF,
  VOC, AU, MP3 (dr_mp3), Ogg Vorbis (stb_vorbis) and FLAC (dr_flac), and
  mixes tracks. rbgame uses it two ways: `Sound.load` decodes a whole file
  through its `AudioDecoder` into the PCM clips `Mixer` already plays, and
  `Music` (`src/music.rs`, `lib/rbgame/music.rb`) streams one track on a
  mixer of its own, with loops, fades and gain. Its bundled TiMidity
  (MIDI) is a separate crate under the Artistic or LGPL license, so the
  dependency is `default-features = false` and rbgame's `midi` cargo
  feature turns it on for those who want it. `Mixer` itself runs on
  SDL_mixer's tracks (`src/mixer.rs`): every `play` is a `Channel` of its
  own, so clips overlap, with volume, pan, loops and fades; `Mixer.offline`
  mixes without a device, which is how the tests hear the result.
* **Images.** The workspace now has `sdl3-image`, the SDL_image
  translation, pinned at the same revision as `sdl3` (`rake sdl:update`
  moves both). `Surface.load` and `Surface#save` go through it, so every
  format it reads and writes is rbgame's, and `Animation` wraps its
  animation API (GIF, APNG, ANI, WebP, and AVIF image sequences for
  loading). WebP (libwebp), TIFF (libtiff's reader), AVIF (libavif over
  dav1d), JPEG XL (libjxl's decoder) and APNG (libpng with zlib, decoding
  and encoding) are translated too, so those load
  with no change in rbgame; the tests decode the translation's own
  sample pictures and sequence from `test/fixtures`. AVIF saving waits on
  an AV1 encoder upstream.
* **The GPU renderer** ("gpu", on SDL's GPU API with Vulkan and Direct3D
  12 backends) sits after "vulkan" in the renderer list, so OpenGL stays
  the default on a display and `Display.renderers` simply lists one more.
  `sdl3-test`, the SDL_test translation, is for the crate's own tests.
* **Gamepads.** The HIDAPI gamepad drivers (Xbox, PlayStation, Nintendo,
  Steam and many more), Linux evdev, Windows GameInput/RawInput/WGI and
  macOS IOKit and MFi (GameController) feed SDL's gamepad layer, which `Rbgame::Gamepad` wraps (`src/gamepad.rs`,
  `lib/rbgame/gamepad.rb`): named buttons and axes, `Event::Gamepad*`, and
  `Gamepad::Virtual` over SDL's virtual joystick so the tests drive a pad
  without hardware. Keyboard and mouse arrive through the same event queue
  rbgame already drains, so they work on a display as they did headless.
* **Cameras.** The V4L2, PipeWire, Media Foundation and CoreMedia
  (AVFoundation) drivers feed SDL's camera layer, which `Rbgame::Camera` wraps (`src/camera.rs`,
  `lib/rbgame/camera.rb`): devices, formats, permission, frames as
  `Surface`s, and `Event::Camera*`. Tests run on SDL's dummy camera driver
  (`RBGAME_CAMERA_DRIVER=dummy`), which is what a machine without a webcam
  sees; a real capture needs a device.
* **Clipboard and touch.** `Clipboard` and `Event::Finger*` wrap what the
  video layer has had all along.
* **Fonts.** `sdl3-ttf` (pinned with the others) is SDL_ttf with the
  FreeType and HarfBuzz it bundles, translated. `Rbgame::Font`
  (`src/font.rs`, `lib/rbgame/font.rb`) loads a font file in any format
  FreeType reads (TrueType, OpenType, Type 1, CID, Type 42, PFR, Windows
  FNT, PCF, BDF), measures and renders text to Surfaces (blended,
  wrapped; OpenType SVG glyphs in their own colours through the PlutoSVG
  translation; shaping through OpenType or AAT tables), and sets style,
  outline and size; `Canvas#text(font:)` draws with one. The tests render
  DejaVu subsets (TrueType, Type 1 and SVG-glyph versions) vendored under
  `test/fixtures` with their license. Not wrapped: text objects and the renderer and GPU text engines
  (glyph atlases); a render per string is enough for a game's HUD, and
  the engines can follow when a game needs thousands of glyphs a frame.
* **SDL_rtf.** `sdl3-rtf` renders RTF documents through `sdl3-ttf`; not
  game material, so not wrapped.
* **SDL_shadercross.** `sdl3-shadercross` reflects SPIR-V and
  cross-compiles it to MSL and HLSL for SDL's GPU API. rbgame draws
  through the 2D renderer and has no GPU API of its own, so there is
  nothing for a shader to attach to; it is not wrapped, and would come
  with a GPU layer if one is ever wanted.
* **SDL_net.** `sdl3-net` (TCP, UDP, address resolution) is not wrapped:
  Ruby's own `socket` library already does this for a Ruby game, and a
  native copy of it would add nothing.
* **Power, locale and sensors.** The power dispatcher got its Linux
  (UPower, sysfs, `/proc/acpi`, `/proc/apm`), Windows and macOS (IOKit)
  backends, so `Rbgame::Power` (`lib/rbgame/power.rb`) reads the battery;
  the locale list (`LANGUAGE`/`LANG` on Unix, the UI languages on Windows,
  `NSLocale` on macOS) is `Rbgame::Locale`; the sensor layer got its Windows driver, which
  `Rbgame::Sensor` (`src/sensor.rs`, `lib/rbgame/sensor.rb`) wraps, with
  `Sensor::None` on Linux where only the dummy driver exists. Gamepad
  sensors (the joystick layer's accelerometers and gyroscopes) are
  `Gamepad#enable`, `#gyroscope`, `#accelerometer` and
  `Event::GamepadSensor`; `Gamepad::Virtual#tilt` sends readings through
  SDL's virtual joystick, which is how the tests see real values. The
  tests read the locale list in child processes because SDL snapshots the
  environment when it starts.
* **Platform plumbing rbgame does not need.** The Unix and Windows time,
  timer and filesystem backends sit under what `Clock` and SDL's own
  loading already use; `sdl3::process` and `sdl3::time` duplicate Ruby's
  `Process` and `Time`; `sdl3::misc::open_url` is Ruby's `system` or a
  gem away. Renderer internals (wrapping existing GL, Vulkan and Direct3D
  textures and objects, OpenGL ES 3 shaders, GPU renderers without a
  window) change nothing a Ruby game can see.
* **Not wrapped, and why.** Haptics: `Gamepad#rumble` covers what games
  use; SDL's effect API (springs, ramps, custom waveforms) can follow on
  request. Dialogs, notifications, trays and message boxes: desktop
  integration (portals and zenity on Unix, `IFileDialog`, toasts and the
  notification area on Windows, Cocoa panels, status items and
  UserNotifications on macOS), not game loop material; they can be
  wrapped when wanted.

The rule for an update that brings a new subsystem: wrap it. A capability
that is only in the crate is not in rbgame; it gets a thin native class, a
Ruby object designed for games (with a null object where "none plugged in"
is normal), events where it has them, tests that run headless, a changelog
line and a row in the README's tour.

Still worth watching:

* **The mobile backends** (UIKit, Android), should rbgame ever want to run
  there; nothing in the Ruby layer assumes a desktop.

### Where rbgame touches the crate

All of it is under `src/`, and it is small on purpose. `grep -n "sdl3::" src/*.rs`
lists every entry point used. If an update renames something, the compiler
says exactly where; the Ruby side (`lib/`) never sees SDL types.

## Rutie

Rutie tracks Ruby's C API per Ruby line (see its README table): 0.13 for Ruby
3.2–3.4, 0.14 for Ruby 4.0. `Cargo.toml` names the line; change it when you
change Ruby. The `rutie` *gem* (the loader) is version-independent.
