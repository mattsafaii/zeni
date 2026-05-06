# frozen_string_literal: true

require "date"

module Zeni
  class PromptBuilder
    SYSTEM = <<~PROMPT
      You are an hledger journal entry assistant. Given a plain-language expense description,
      return a JSON object with this exact structure:

      {
        "date": "YYYY-MM-DD",
        "description": "Short payee name",
        "postings": [
          { "account": "expenses:category:subcategory", "amount": "15.00 USD" },
          { "account": "assets:account:name", "amount": "-15.00 USD" }
        ]
      }

      Rules:
      - CRITICAL: Every account in postings MUST be copied EXACTLY from the "Valid accounts" list below. No modifications, no extra segments, no sub-accounts. If you use an account not in that list, the entry is invalid.
      - Amounts must balance to zero (debits = credits).
      - Use the currency from defaults (default: USD).
      - Date is today unless explicitly stated.
      - Return ONLY the JSON object, no explanation.
    PROMPT

    def self.build(config:, journal:, user_input:, context:)
      accounts_section = build_accounts(config)
      aliases_section  = build_aliases(config)
      vendors_section  = build_vendors(config)
      recent_section   = journal.recent_entries(count: 20)

      system_prompt = [
        SYSTEM.strip,
        "## Valid accounts (use ONLY these, copied exactly)",
        accounts_section,
        "## Aliases (shorthand → full account name)",
        aliases_section,
        "## Known vendor mappings",
        vendors_section,
        "## Recent journal entries (style reference)",
        recent_section.empty? ? "(no entries yet)" : recent_section
      ].join("\n\n")

      user_message = "Date: #{Date.today}\nContext: #{context}\nInput: #{user_input}"

      { system: system_prompt, user: user_message }
    end

    def self.build_accounts(config)
      return "(not configured)" if config.journals.empty?
      config.journals.flat_map do |ctx, journal_path|
        journal_dir = File.dirname(File.expand_path(journal_path))
        accounts_file = File.join(journal_dir, "accounts.journal")
        next ["# context: #{ctx} (no accounts.journal found)"] unless File.exist?(accounts_file)

        lines = File.readlines(accounts_file, chomp: true)
          .reject { |l| l.strip.empty? || l.strip.start_with?(";") }
          .map { |l| l.sub(/^account\s+/, "") }
        ["# context: #{ctx}"] + lines
      end.join("\n")
    end

    def self.build_aliases(config)
      return "(none)" if config.aliases.empty?
      config.aliases.map { |k, v| "#{k} = #{v}" }.join("\n")
    end

    def self.build_vendors(config)
      return "(none)" if config.vendors.empty?
      config.vendors.map { |k, v| "#{k} -> #{v}" }.join("\n")
    end
  end
end
