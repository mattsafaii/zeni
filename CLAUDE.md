# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and install

After making changes, rebuild and reinstall the gem locally:

```
gem build zeni.gemspec && gem install zeni-0.1.0.gem
```

Run directly from the repo without installing:

```
bundle exec exe/zeni "description"
```

## Architecture

zeni is a Ruby CLI gem. The entry point is `exe/zeni`, which calls `Zeni::CLI.start(ARGV)`.

**Request flow for `zeni "tacos 12 cash"`:**

1. `CLI#start` intercepts args — if the first arg isn't a known subcommand, prepends `log` so bare descriptions work
2. `CLI#log` orchestrates the full flow:
   - `Config` loads `~/.config/zeni/config.toml` and the `accounts.journal` for the active context
   - `PromptBuilder` assembles the Ollama system prompt (accounts list, aliases, vendors, recent journal entries) and user message
   - `Ollama#generate` POSTs to `/api/generate` with a JSON schema that constrains the `account` field to an enum of valid accounts — this is the primary guard against hallucinated account names
   - `CLI#snap_accounts` is a fallback that prefix-matches any account that slipped through to the nearest valid one
   - `Formatter` renders the JSON response as an hledger entry string
   - `Prompt` shows the entry and asks for confirmation (skipped with `-y`)
   - `Journal#validate!` runs `hledger check`, then `Journal#append` writes to the file
   - `Config#save_vendor` updates `~/.config/zeni/vendors.toml` with the learned mapping

**Key design decisions:**
- Account correctness is enforced structurally via the Ollama JSON schema enum, not just via prompt instructions (models ignore prompt constraints)
- `temperature: 0` on all Ollama calls for determinism
- No external HTTP calls — Ollama runs locally at `http://localhost:11434`
- Default model: `qwen3:latest`, overridable via `ZENI_MODEL` env var
- Config lives at `~/.config/zeni/config.toml`; accounts are read from `accounts.journal` in the same directory as each configured journal file

## Config

`~/.config/zeni/config.toml` must exist with at least one journal and a default context. See README for full structure.
