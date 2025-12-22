require "net/http"

module Llm
  class GeminiClient
    def initialize(api_key:)
      @api_key = api_key
    end

    def stream(messages:, model:, &block)
      uri = gemini_uri(model)
      request_body = gemini_request_body(messages)
      log_gemini_request(uri, request_body)

      http = gemini_http_client(uri)
      req = gemini_request(uri, request_body)
      state = gemini_stream_state

      http.request(req) do |res|
        log_gemini_response(res)
        raise_gemini_error!(res) unless res.code == "200"

        res.read_body do |chunk|
          process_gemini_chunk(chunk, state, &block)
        end
      end

      finalize_gemini_stream(state, &block)
      Rails.logger.info "[Gemini] ストリーミング完了 (#{state[:chunk_count]}チャンク)"
    rescue StandardError => e
      Rails.logger.error "[Gemini] エラー: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise
    end

    private

    def gemini_uri(model)
      uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{model}:streamGenerateContent")
      uri.query = URI.encode_www_form(alt: "sse")
      uri
    end

    def gemini_http_client(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 300
      http
    end

    def gemini_request(uri, request_body)
      req = Net::HTTP::Post.new(uri)
      req["x-goog-api-key"] = @api_key
      req["Content-Type"] = "application/json"
      req["Accept"] = "text/event-stream"
      req.body = request_body.to_json
      req
    end

    def gemini_request_body(messages)
      {
        contents: messages.map { |message| format_gemini_message(message) },
        generationConfig: {
          thinkingConfig: { thinkingBudget: 0 },
          maxOutputTokens: 1024
        }
      }
    end

    def format_gemini_message(message)
      role = message[:role] || message["role"]
      content = message[:content] || message["content"]
      role = normalize_gemini_role(role)

      {
        role: role,
        parts: [ { text: content.to_s } ]
      }
    end

    def normalize_gemini_role(role)
      role = role.to_s
      return "model" if role == "assistant"
      return "user" if role == "system"

      role
    end

    def gemini_stream_state
      request_started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      Rails.logger.info "[Gemini] リクエスト開始 t=#{request_started_at}"

      {
        raw_body: +"",
        chunk_count: 0,
        emitted: false,
        logged_payload_keys: false,
        sse_data: +"",
        line_buffer: +"",
        request_started_at: request_started_at
      }
    end

    def log_gemini_request(uri, request_body)
      Rails.logger.info "[Gemini] リクエストURL: #{uri.host}#{uri.path}"
      Rails.logger.info "[Gemini] リクエストボディ: #{request_body.to_json}"
    end

    def log_gemini_response(res)
      Rails.logger.info "[Gemini] レスポンスステータス: #{res.code}"
      Rails.logger.info "[Gemini] レスポンスContent-Type: #{res["Content-Type"]}"
    end

    def raise_gemini_error!(res)
      error_body = res.body
      Rails.logger.error "[Gemini] エラーレスポンス: #{error_body}"
      raise "Gemini API error (#{res.code}): #{error_body}"
    end

    def process_gemini_chunk(chunk, state)
      if state[:chunk_count].zero?
        first_chunk_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        delta = (first_chunk_at - state[:request_started_at])
        Rails.logger.info "[Gemini] 初回チャンクまでの時間=#{delta.round(3)}s t=#{first_chunk_at}"
      end

      state[:chunk_count] += 1
      Rails.logger.info "[Gemini] チャンク##{state[:chunk_count]} (#{chunk.bytesize}バイト) t=#{Process.clock_gettime(Process::CLOCK_MONOTONIC)}"

      state[:raw_body] << chunk
      state[:line_buffer] << chunk
      lines = state[:line_buffer].split("\n", -1)
      state[:line_buffer] = lines.pop || ""

      lines.each do |line|
        line = line.chomp("\r")
        if line.strip.empty?
          state[:logged_payload_keys] = emit_sse_payload!(state[:sse_data], state[:logged_payload_keys]) do |text|
            state[:emitted] = true
            Rails.logger.debug "[Gemini] テキスト抽出: #{text[0..50]}..."
            yield text
          end
          next
        end

        line = line.strip
        next if line.start_with?(":")
        next unless line.start_with?("data:")

        data = line.sub(/\Adata:\s*/, "")
        next if data == "[DONE]"

        state[:sse_data] << "\n" unless state[:sse_data].empty?
        state[:sse_data] << data
      end
    end

    def finalize_gemini_stream(state)
      unless state[:line_buffer].strip.empty?
        state[:sse_data] << "\n" unless state[:sse_data].empty?
        state[:sse_data] << state[:line_buffer].strip
      end

      state[:logged_payload_keys] = emit_sse_payload!(state[:sse_data], state[:logged_payload_keys]) do |text|
        state[:emitted] = true
        Rails.logger.debug "[Gemini] テキスト抽出: #{text[0..50]}..."
        yield text
      end

      return if state[:emitted]

      parse_gemini_payloads(state[:raw_body]).each do |payload|
        text = extract_gemini_text(payload)
        if text.blank?
          if !state[:logged_payload_keys] && payload.is_a?(Hash)
            Rails.logger.info "[Gemini] ペイロードキー: #{payload.keys}"
            state[:logged_payload_keys] = true
          end
          next
        end

        Rails.logger.debug "[Gemini] テキスト抽出(後処理): #{text[0..50]}..."
        yield text
      end
    end

    def emit_sse_payload!(sse_data, logged_payload_keys)
      return logged_payload_keys if sse_data.blank?

      payload = parse_json_payload(sse_data)
      sse_data.clear
      return logged_payload_keys unless payload

      each_gemini_payload(payload) do |item|
        text = extract_gemini_text(item)
        if text.blank?
          if !logged_payload_keys && item.is_a?(Hash)
            Rails.logger.info "[Gemini] ペイロードキー: #{item.keys}"
            logged_payload_keys = true
          end
          next
        end

        yield text
      end

      logged_payload_keys
    end

    def parse_gemini_payloads(raw_body)
      payloads = []
      sse_events = extract_sse_events(raw_body)
      if sse_events.any?
        sse_events.each do |event_data|
          payload = parse_json_payload(event_data)
          payloads << payload if payload
        end
        return payloads
      end

      payload = parse_json_payload(raw_body)
      return normalize_gemini_payloads(payload) if payload

      raw_body.each_line do |line|
        line = line.strip
        next if line.empty? || line == "," || line == "[" || line == "]"
        line = line.chomp(",")

        payload = parse_json_payload(line)
        payloads.concat(normalize_gemini_payloads(payload)) if payload
      end

      payloads
    end

    def extract_sse_events(raw_body)
      events = raw_body.split(/\r?\n\r?\n/)
      events.filter_map do |event|
        data_lines = event.lines.filter_map do |line|
          line = line.strip
          next unless line.start_with?("data:")

          line.sub(/\Adata:\s*/, "")
        end
        next if data_lines.empty?

        data = data_lines.join("\n")
        next if data == "[DONE]"

        data
      end
    end

    def parse_json_payload(data)
      return nil unless data.is_a?(String)

      JSON.parse(data)
    rescue JSON::ParserError
      nil
    end

    def normalize_gemini_payloads(payload)
      return [] unless payload
      return payload.filter_map { |item| item.is_a?(Hash) ? item : nil } if payload.is_a?(Array)
      return [ payload ] if payload.is_a?(Hash)

      []
    end

    def each_gemini_payload(payload)
      normalize_gemini_payloads(payload).each { |item| yield item }
    end

    def extract_gemini_text(payload)
      return nil unless payload.is_a?(Hash)

      candidates = payload["candidates"]
      candidates ||= payload.dig("response", "candidates")
      return nil unless candidates.is_a?(Array)

      texts = candidates.flat_map do |candidate|
        parts = candidate.dig("content", "parts")
        next [] unless parts.is_a?(Array)

        parts.filter_map { |part| part["text"] }
      end

      return nil if texts.empty?

      texts.join
    end
  end
end
