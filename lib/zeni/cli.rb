# frozen_string_literal: true

require "thor"

module Zeni
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    KNOWN_COMMANDS = %w[log undo switch help tree].freeze

    def self.start(args = ARGV, config = {})
      if args.first && !args.first.start_with?("-") && !KNOWN_COMMANDS.include?(args.first)
        args = ["log"] + args
      end
      super(args, config)
    end

    class_option :config, type: :string, desc: "Path to config.toml (default: ~/.config/zeni/config.toml)"

    desc "log DESCRIPTION", "Log a transaction (default command)"
    method_option :yes, aliases: "-y", type: :boolean, default: false, desc: "Skip confirmation prompt"
    method_option :context, aliases: "-c", type: :string, desc: "Override active journal context"
    def log(description)
      config  = load_config
      context = options[:context] || config.active_context(cwd: Dir.pwd)
      journal = Journal.new(config.active_journal(context: options[:context], cwd: Dir.pwd))
      ollama  = Ollama.new
      prompt  = Prompt.new

      prompts = PromptBuilder.build(
        config: config,
        journal: journal,
        user_input: description,
        context: context
      )

      valid_accounts = config.known_accounts(context)

      puts "Thinking..."
      data = ollama.generate(
        model: detect_model,
        system: prompts[:system],
        user: prompts[:user],
        valid_accounts: valid_accounts
      )

      data = snap_accounts(data, valid_accounts) unless valid_accounts.empty?
      entry = Formatter.format(data, aliases: config.aliases)

      confirmed = prompt.confirm_entry(entry, skip: options[:yes])
      unless confirmed
        puts "Cancelled."
        return
      end

      journal.append_validated(entry)

      if (vendor_account = data.dig("postings", 0, "account"))
        config.save_vendor(description, vendor_account)
      end

      puts "Appended."
    rescue Error => e
      $stderr.puts "Error: #{e.message}"
      exit 1
    end

    default_task :log

    desc "undo", "Remove the last appended entry from the active journal"
    def undo
      config  = load_config
      journal = Journal.new(config.active_journal(cwd: Dir.pwd))

      if journal.undo
        puts "Last entry removed."
      else
        puts "Nothing to undo."
      end
    rescue Error => e
      $stderr.puts "Error: #{e.message}"
      exit 1
    end

    desc "switch CONTEXT", "Change default context for this session"
    def switch(context)
      config = load_config
      unless config.journals.key?(context)
        $stderr.puts "Unknown context '#{context}'. Available: #{config.journals.keys.join(', ')}"
        exit 1
      end
      puts "Switched to context: #{context}"
      puts "(Note: context switches are per-session via -c flag or config default)"
    rescue Error => e
      $stderr.puts "Error: #{e.message}"
      exit 1
    end

    private

    # Replace any hallucinated account with the best prefix match from valid_accounts
    def snap_accounts(data, valid_accounts)
      data["postings"] = data["postings"].map do |posting|
        account = posting["account"]
        next posting if valid_accounts.include?(account)

        best = valid_accounts.max_by do |valid|
          common_prefix_length(account, valid)
        end
        posting.merge("account" => best)
      end
      data
    end

    def common_prefix_length(a, b)
      a_parts = a.split(":")
      b_parts = b.split(":")
      a_parts.zip(b_parts).take_while { |x, y| x == y }.length
    end

    def load_config
      path = options[:config]
      path ? Config.new(config_path: path) : Config.new
    end

    def detect_model
      ENV.fetch("ZENI_MODEL", "qwen3:latest")
    end
  end
end
