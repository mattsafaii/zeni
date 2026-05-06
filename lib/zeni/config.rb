# frozen_string_literal: true

require "toml-rb"
require "pathname"

module Zeni
  class Config
    CONFIG_DIR = Pathname.new(File.expand_path("~/.config/zeni"))
    CONFIG_PATH = CONFIG_DIR / "config.toml"
    VENDORS_PATH = CONFIG_DIR / "vendors.toml"

    attr_reader :journals, :aliases, :defaults, :vendors

    def initialize(config_path: CONFIG_PATH, vendors_path: VENDORS_PATH)
      @config_path = Pathname.new(config_path)
      @vendors_path = Pathname.new(vendors_path)
      load!
    end

    def active_context(cwd: Dir.pwd)
      detect_context(cwd) || @defaults["context"] || "personal"
    end

    def known_accounts(context)
      journal_path = @journals[context] or return []
      journal_dir = File.dirname(File.expand_path(journal_path))
      accounts_file = File.join(journal_dir, "accounts.journal")
      return [] unless File.exist?(accounts_file)

      File.readlines(accounts_file, chomp: true)
        .map { |l| l.strip }
        .select { |l| l.start_with?("account ") }
        .map { |l| l.sub(/^account\s+/, "") }
    end

    def active_journal(context: nil, cwd: Dir.pwd)
      ctx = context || active_context(cwd: cwd)
      path = @journals[ctx] or raise Error, "No journal configured for context '#{ctx}'"
      File.expand_path(path)
    end

    def vendor_for(description)
      normalized = description.downcase.split.first
      @vendors[normalized]
    end

    def save_vendor(description, account)
      key = description.downcase.split.first
      @vendors[key] = account
      @vendors_path.parent.mkpath
      @vendors_path.write(TomlRB.dump(@vendors))
    end

    private

    def load!
      raw = @config_path.exist? ? TomlRB.load_file(@config_path) : {}
      @journals = raw["journals"] || {}
      @aliases = raw["aliases"] || {}
      @defaults = raw["defaults"] || {}
      @vendors = @vendors_path.exist? ? TomlRB.load_file(@vendors_path) : {}
    end

    # Match cwd against journal paths to auto-detect context
    def detect_context(cwd)
      cwd_path = Pathname.new(cwd).expand_path
      @journals.each do |context, journal_path|
        journal_dir = Pathname.new(File.expand_path(journal_path)).dirname
        return context if cwd_path.to_s.start_with?(journal_dir.to_s)
      end
      nil
    end
  end
end
