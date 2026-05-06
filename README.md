# zeni

Natural language hledger journal entry via local Ollama. Type a plain-language expense and zeni formats, confirms, validates, and appends a hledger entry. Everything runs locally - no data leaves your machine.

```
zeni "tacos 12 cash"
```

```
Thinking...

2026-05-06 tacos
    expenses:personal:food                            12.00 USD
    assets:personal:cash                              -12.00 USD
Append this entry? (Y/n)
```

## Requirements

- Ruby 3.2+
- [hledger](https://hledger.org/install.html)
- [Ollama](https://ollama.com) running locally with at least one model pulled

```
ollama pull qwen3:latest
```

## Installation

```
gem install zeni
```

Or from source:

```
git clone https://github.com/mattsafaii/zeni
cd zeni
gem build zeni.gemspec && gem install zeni-0.1.0.gem
```

## Configuration

Create `~/.config/zeni/config.toml`:

```toml
[journals]
personal  = "~/Documents/Finances/personal/2026.journal"
business  = "~/Documents/Finances/business/2026.journal"

[aliases]
cash   = "assets:personal:cash"
chase  = "assets:personal:checking:chase"
cc     = "liabilities:personal:creditcard"

[defaults]
currency = "USD"
context  = "personal"
```

**Journals** - one key per context. The active journal is selected automatically based on your current directory, or falls back to `defaults.context`.

**Aliases** - shorthand you can use in descriptions instead of full account names.

**Accounts** - zeni reads `accounts.journal` from the same directory as each journal file and uses those accounts to constrain what the model can output. Keep an `accounts.journal` next to each journal. Format:

```
account assets:personal:cash
account assets:personal:checking:chase
account liabilities:personal:creditcard
account expenses:personal:food
account expenses:personal:transportation
```

**Context auto-detection** - if your cwd is inside the same directory as a configured journal, zeni activates that context automatically. For example, if `business` points to `~/work/finances/2026.journal` and you run zeni from anywhere inside `~/work/finances/`, it uses the business journal without needing `-c`.

## Usage

### Log a transaction

```
zeni "description"
zeni log "description"
```

zeni sends the description to Ollama, shows you the formatted entry, and asks for confirmation before appending.

### Skip confirmation

```
zeni -y "description"
zeni --yes "description"
```

### Override context

```
zeni -c business "Digital Ocean invoice 42 cc"
```

### Switch default context

```
zeni switch business
```

### Undo last entry

```
zeni undo
```

Removes the last appended transaction block from the active journal.

### Help

```
zeni help
zeni help log
zeni help undo
```

## How it works

1. Determines active context from cwd or config default
2. Loads your chart of accounts from `accounts.journal`
3. Reads last 20 entries from the active journal for style context
4. Sends a structured prompt to Ollama with a JSON schema - accounts are constrained to an enum of your valid accounts so the model cannot hallucinate
5. Formats the JSON response into an hledger entry
6. Shows the entry and asks for confirmation
7. Runs `hledger check` to validate
8. Appends to journal and updates `vendors.toml` with the learned mapping

## Model

Default model is `qwen3:latest`. Override with the `ZENI_MODEL` environment variable:

```
ZENI_MODEL=llama3.1:latest zeni "coffee 6 chase"
```

## Development

```
git clone https://github.com/mattsafaii/zeni
cd zeni
bundle install
bundle exec exe/zeni "test entry"
```

After making changes, rebuild and reinstall:

```
gem build zeni.gemspec && gem install zeni-0.1.0.gem
```
