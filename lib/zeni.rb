# frozen_string_literal: true

require_relative "zeni/version"
require_relative "zeni/config"
require_relative "zeni/journal"
require_relative "zeni/ollama"
require_relative "zeni/formatter"
require_relative "zeni/prompt"
require_relative "zeni/prompt_builder"
require_relative "zeni/cli"

module Zeni
  class Error < StandardError; end
end
