# frozen_string_literal: true

require_relative "lib/zeni/version"

Gem::Specification.new do |spec|
  spec.name = "zeni"
  spec.version = Zeni::VERSION
  spec.authors = ["Matt Safaii"]
  spec.email = ["matt@mattsafaii.com"]

  spec.summary = "Natural language hledger entry via local Ollama"
  spec.description = "Type a plain-language expense and zeni formats, confirms, validates, and appends a hledger journal entry. All local, no cloud."
  spec.homepage = "https://github.com/mattsafaii/zeni"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "toml-rb", "~> 3.0"
end
