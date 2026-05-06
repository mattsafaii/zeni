# frozen_string_literal: true

require "date"

module Zeni
  class Formatter
    # Takes the Ollama JSON response and returns a formatted hledger entry string.
    # Expected input:
    #   {
    #     "date"        => "2026-05-06",
    #     "description" => "Tacos al pastor",
    #     "postings"    => [
    #       { "account" => "expenses:food:restaurants", "amount" => "15 USD" },
    #       { "account" => "assets:cash:wallet",        "amount" => "-15 USD" }
    #     ]
    #   }
    def self.format(data, aliases: {})
      date        = data["date"] || Date.today.to_s
      description = data["description"] or raise Error, "Ollama response missing 'description'"
      postings    = data["postings"]
      raise Error, "Ollama response missing 'postings'" if postings.nil? || postings.empty?

      lines = ["#{date} #{description}"]
      postings.each do |p|
        account = resolve_alias(p["account"], aliases)
        amount  = p["amount"]
        raise Error, "Posting missing 'account'" if account.nil? || account.empty?
        if amount
          lines << "    #{account.ljust(48)}  #{amount}"
        else
          lines << "    #{account}"
        end
      end
      lines.join("\n") + "\n"
    end

    def self.resolve_alias(account, aliases)
      aliases[account] || account
    end
    private_class_method :resolve_alias
  end
end
