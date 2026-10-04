# frozen_string_literal: true

require "rake/testtask"
require "rutie/rake_task"

# `rake rutie:build` compiles the Rust extension (cargo build --release);
# `rake rutie:clean` removes the build.
Rutie::RakeTask.new

Rake::TestTask.new(test: "rutie:build") do |t|
  t.libs << "test" << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
end

namespace :gorillas do
  desc "Play the Gorillas demo"
  task play: "rutie:build" do
    ruby "-Ilib", "-Iexamples/gorillas/lib", "examples/gorillas/bin/gorillas"
  end

  desc "Run the Gorillas demo unattended and save frames (DIR=tmp/frames FRAMES=600)"
  task record: "rutie:build" do
    dir = ENV.fetch("DIR", "tmp/frames")
    frames = ENV.fetch("FRAMES", "600")
    ruby "-Ilib", "-Iexamples/gorillas/lib", "examples/gorillas/bin/gorillas",
         "--autoplay", "--record", dir, "--frames", frames
  end

  Rake::TestTask.new(test: "rutie:build") do |t|
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
    File.write("Cargo.toml", cargo_toml.sub(/(sdl3 = \{[^}]*rev = ")\h+(")/, "\\1#{rev}\\2"))
    sh "cargo", "update", "-p", "sdl3"
    sh "cargo", "build", "--release"
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
