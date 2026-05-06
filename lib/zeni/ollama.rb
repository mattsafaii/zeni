# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Zeni
  class Ollama
    BASE_URL = "http://localhost:11434"
    TIMEOUT = 90

    def initialize(url: BASE_URL)
      uri = URI.parse(url)
      @host = uri.host
      @port = uri.port
    end

    # Sends prompt to Ollama with a JSON schema to constrain the response.
    # valid_accounts is an array of account strings to use as enum values.
    def generate(model:, system:, user:, valid_accounts: [])
      body = JSON.generate({
        model: model,
        system: system,
        prompt: user,
        stream: false,
        options: { temperature: 0 },
        format: build_schema(valid_accounts)
      })

      response = post("/api/generate", body)
      raw = JSON.parse(response)
      content = raw["response"] or raise Error, "Unexpected Ollama response shape"
      JSON.parse(content)
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError => e
      raise Error, "Ollama unavailable — is it running? (#{e.message})"
    rescue Net::ReadTimeout
      raise Error, "Ollama timed out after #{TIMEOUT}s"
    rescue JSON::ParserError => e
      raise Error, "Ollama returned non-JSON: #{e.message}"
    end

    private

    def build_schema(valid_accounts)
      account_schema = valid_accounts.any? ? { "type" => "string", "enum" => valid_accounts } : { "type" => "string" }

      {
        "type" => "object",
        "properties" => {
          "date"        => { "type" => "string" },
          "description" => { "type" => "string" },
          "postings"    => {
            "type" => "array",
            "items" => {
              "type" => "object",
              "properties" => {
                "account" => account_schema,
                "amount"  => { "type" => "string" }
              },
              "required" => %w[account amount]
            }
          }
        },
        "required" => %w[date description postings]
      }
    end

    def post(path, body)
      Net::HTTP.start(@host, @port, read_timeout: TIMEOUT, open_timeout: 5) do |http|
        req = Net::HTTP::Post.new(path, "Content-Type" => "application/json")
        req.body = body
        res = http.request(req)
        raise Error, "Ollama HTTP #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)
        res.body
      end
    end
  end
end
