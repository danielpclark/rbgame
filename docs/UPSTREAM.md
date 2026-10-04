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

The translation's `README.md` and `docs/ROADMAP.md` list what is done. The
items that change what rbgame can do:

* **Platform video backends** (Wayland, X11, Windows, Cocoa). Today the crate
  has only the `dummy` and `offscreen` drivers, so rbgame opens no visible
  window anywhere yet: it draws into an offscreen framebuffer, which is what
  the tests and the Gorillas recorder use. The moment a platform backend
  lands, `Rbgame.init` picks it up with no change here (see `init_video` in
  `lib/rbgame.rb`: the offscreen fallback only applies when no other driver
  exists). Likewise input: real keyboard and mouse events arrive through the
  same event queue rbgame already drains.
* **Audio drivers** (PipeWire, PulseAudio, ALSA, WASAPI, CoreAudio). `Mixer`
  already opens the default playback device; with the `dummy` driver it plays
  into the void. A real driver makes it audible.
* **GPU renderers** (OpenGL, Vulkan, Metal). `Display.set_mode(driver: ...)`
  passes a renderer name through; the default stays SDL's choice.
* **SDL_image / SDL_ttf** satellite translations. `Surface.load` reads BMP
  because that is what SDL reads on its own; PNG/JPEG and real fonts come
  with those crates. `Canvas#text` uses SDL's 8x8 debug font until then.

### Where rbgame touches the crate

All of it is under `src/`, and it is small on purpose. `grep -n "sdl3::" src/*.rs`
lists every entry point used. If an update renames something, the compiler
says exactly where; the Ruby side (`lib/`) never sees SDL types.

## Rutie

Rutie tracks Ruby's C API per Ruby line (see its README table): 0.13 for Ruby
3.2–3.4, 0.14 for Ruby 4.0. `Cargo.toml` names the line; change it when you
change Ruby. The `rutie` *gem* (the loader) is version-independent.
