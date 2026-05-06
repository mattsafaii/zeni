# frozen_string_literal: true

require "tty-prompt"

module Zeni
  class Prompt
    def initialize
      @prompt = TTY::Prompt.new
    end

    # Shows the formatted entry and asks for confirmation.
    # Returns true if confirmed, false if cancelled.
    # If skip is true, prints the entry and returns true without asking.
    def confirm_entry(entry_text, skip: false)
      puts "\n#{entry_text}"
      return true if skip

      @prompt.yes?("Append this entry?", default: true)
    end
  end
end
