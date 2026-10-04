# frozen_string_literal: true

require "rutie"

module Rbgame
  # Loads the Rust extension (`target/<profile>/librbgame_native.so`), which
  # defines Rbgame::Native: the thin, primitive-argument face of SDL that
  # the rest of this gem builds on. Nothing outside lib/rbgame should need to
  # talk to Rbgame::Native directly.
  #
  # The profile defaults to `release`; set RBGAME_NATIVE_PROFILE=debug to
  # load a `cargo build` without `--release`.
  module NativeLoader
    PROFILE_ENV = "RBGAME_NATIVE_PROFILE"
    LIB_DIR_ENV = "RBGAME_NATIVE_LIB_DIR"

    module_function

    def load!
      options = { release: ENV.fetch(PROFILE_ENV, "release") }
      options[:lib_path] = ENV[LIB_DIR_ENV] if ENV[LIB_DIR_ENV]
      Rutie.new(:rbgame_native, **options).init(File.expand_path("..", __dir__))
    rescue LoadError => e
      raise NativeLoadError, <<~MESSAGE.strip
        #{e.message}

        Build it with `bundle exec rake rutie:build` (or `cargo build --release`).
      MESSAGE
    end
  end

  NativeLoader.load!
end
