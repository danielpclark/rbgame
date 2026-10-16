# frozen_string_literal: true

require "rake/testtask"

# `rake rutie:build` compiles the Rust extension (cargo build --release);
# `rake rutie:clean` removes the build. This is the same build bin/setup
# and a bare `cargo build --release` run (build.rs adds the macOS link
# flag, the `no-link` feature leaves libruby out), so cargo reuses it
# instead of rebuilding. Rutie::RakeTask built with NO_LINK_RUTIE and extra
# rustc arguments, which cargo fingerprints, so the two kept rebuilding.
#
# Cargo runs in the environment from before `bundle exec`, too: Bundler
# drops repeated PATH entries, and Rutie's build script reruns whenever
# PATH changes (it is how it notices a switch of Ruby).
def cargo(*args)
  run = -> { sh "cargo", *args }
  defined?(Bundler) ? Bundler.with_original_env(&run) : run.call
end

namespace :rutie do
  desc "Build the Rust extension"
  task(:build) { cargo "build", "--release" }

  desc "Remove the Rust build output (cargo clean)"
  task(:clean) { cargo "clean" }
end

# The built extension, for the tasks that load it: rake runs cargo only
# when it is missing or older than what it is built from, so playing or
# testing an extension that is already built starts straight away.
NATIVE_LIB = File.join("target", "release",
                       case RbConfig::CONFIG["host_os"]
                       when /darwin|mac os/ then "librbgame_native.dylib"
                       when /mswin|mingw|cygwin/ then "rbgame_native.dll"
                       else "librbgame_native.so"
                       end)

file NATIVE_LIB => FileList["src/**/*.rs", "build.rs", "Cargo.toml", "Cargo.lock"] do
  cargo "build", "--release"
  # Cargo leaves the library alone when nothing it tracks changed (a
  # touched file, say); stamp it so the next run doesn't ask again.
  FileUtils.touch(NATIVE_LIB)
end

Rake::TestTask.new(test: NATIVE_LIB) do |t|
  t.libs << "test" << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
end

namespace :gorillas do
  desc "Play the Gorillas demo"
  task play: NATIVE_LIB do
    ruby "-Ilib", "-Iexamples/gorillas/lib", "examples/gorillas/bin/gorillas"
  end

  desc "Run the Gorillas demo unattended and save frames (DIR=tmp/frames FRAMES=600)"
  task record: NATIVE_LIB do
    dir = ENV.fetch("DIR", "tmp/frames")
    frames = ENV.fetch("FRAMES", "600")
    ruby "-Ilib", "-Iexamples/gorillas/lib", "examples/gorillas/bin/gorillas",
         "--autoplay", "--record", dir, "--frames", frames
  end

  Rake::TestTask.new(test: NATIVE_LIB) do |t|
    t.libs << "examples/gorillas/test" << "examples/gorillas/lib" << "lib"
    t.test_files = FileList["examples/gorillas/test/**/*_test.rb"]
    t.warning = false
  end
end

namespace :sdl do
  # The SDL translation (github.com/danielpclark/SDL) moves fast; this keeps
  # the pinned revision in Cargo.toml and Cargo.lock in step with it.
  desc "Report whether the pinned SDL revision is behind upstream"
  task :check do
    pinned = File.read("Cargo.toml", encoding: "UTF-8")[/sdl3 = \{[^}]*rev = "(\h+)"/, 1]
    head = `git ls-remote https://github.com/danielpclark/SDL HEAD`.split.first
    abort "could not reach upstream SDL" if head.nil? || head.empty?
    if head.start_with?(pinned)
      puts "SDL is up to date (#{pinned[0, 12]})"
    else
      puts "SDL has moved: pinned #{pinned[0, 12]}, upstream #{head[0, 12]}. Run `rake sdl:update`."
      exit 1
    end
  end

  desc "Move the pinned SDL revision to upstream HEAD (or REV=<sha>), update Cargo.lock, rebuild"
  task :update do
    rev = ENV["REV"] || `git ls-remote https://github.com/danielpclark/SDL HEAD`.split.first
    abort "could not reach upstream SDL" if rev.nil? || rev.empty?
    cargo_toml = File.read("Cargo.toml", encoding: "UTF-8")
    # Every crate from that repository moves together.
    File.write("Cargo.toml", cargo_toml.gsub(/(danielpclark\/SDL"[^}]*rev = ")\h+(")/, "\\1#{rev}\\2"))
    cargo "update", "-p", "sdl3", "-p", "sdl3-image", "-p", "sdl3-mixer", "-p", "sdl3-ttf"
    cargo "build", "--release"
    puts "SDL pinned to #{rev}. Run the tests, then commit Cargo.toml and Cargo.lock."
  end
end

namespace :rbs do
  desc "Validate the RBS type signatures in sig/"
  task :validate do
    sh "rbs", "-I", "sig", "validate"
  end
end

task default: %i[test gorillas:test rbs:validate]
