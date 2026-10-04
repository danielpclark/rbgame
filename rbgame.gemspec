# frozen_string_literal: true

require_relative "lib/rbgame/version"

Gem::Specification.new do |spec|
  spec.name = "rbgame"
  spec.version = Rbgame::VERSION
  spec.authors = ["Daniel P. Clark"]
  spec.email = ["6ftdan@gmail.com"]

  spec.summary = "Games in Ruby on SDL, with no C anywhere in the stack."
  spec.description = <<~DESC.strip
    rbgame is to Ruby what pygame is to Python: windows, drawing, images, events,
    timing and sound for 2D games. It runs on a pure-Rust translation of SDL 3,
    reached from Ruby through Rutie, so there is no C and no hand-written FFI.
    The API is designed the Ruby way: immutable value objects, blocks, keyword
    arguments, Data classes that pattern match, and a Game class to subclass.
  DESC
  spec.homepage = "https://github.com/danielpclark/rbgame"
  spec.license = "MIT OR Apache-2.0"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*.rb", "src/**/*.rs", "Cargo.toml", "Cargo.lock", "LICENSE-*", "README.md", "CHANGELOG.md"]
  end
  spec.bindir = "exe"
  spec.executables = []
  spec.require_paths = ["lib"]

  spec.add_dependency "rutie", "~> 0.0.5"
end
