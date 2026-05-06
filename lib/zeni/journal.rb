# frozen_string_literal: true

module Zeni
  class Journal
    ENTRY_SEPARATOR = /^(?=\d{4}-\d{2}-\d{2}\s)/

    def initialize(path)
      @path = path
    end

    # Returns the last n complete hledger journal entries as a single string
    def recent_entries(count: 20)
      return "" unless File.exist?(@path)

      content = File.read(@path)
      entries = content.split(ENTRY_SEPARATOR).reject(&:empty?)
      entries.last(count).join
    end

    # Appends a formatted entry to the journal file
    def append(entry_text)
      text = entry_text.end_with?("\n\n") ? entry_text : "#{entry_text.rstrip}\n\n"
      File.open(@path, "a") { |f| f.write(text) }
    end

    # Removes the last appended transaction block (everything after the last blank-line boundary)
    def undo
      return false unless File.exist?(@path)

      content = File.read(@path)
      entries = content.split(ENTRY_SEPARATOR).reject(&:empty?)
      return false if entries.empty?

      entries.pop
      File.write(@path, entries.join)
      true
    end

    # Runs hledger check on this journal; raises Error with stderr on failure
    def validate!
      output = IO.popen(["hledger", "-f", @path, "check"], err: [:child, :out], &:read)
      raise Error, "hledger check failed:\n#{output}" unless $?.success?
    end
  end
end
