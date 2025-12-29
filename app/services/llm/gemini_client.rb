require "net/http"

module Llm
  class GeminiClient
    # API設定
    BASE_URL = "https://generativelanguage.googleapis.com/v1beta"

    # タイムアウト設定
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 300

    # 生成設定
    THINKING_BUDGET = 0
    MAX_OUTPUT_TOKENS = 1024

    # ログ設定
    LOG_TEXT_PREVIEW_LENGTH = 50

    # ロールマッピング
    ROLE_MAPPING = {
      "assistant" => "model",
      "system" => "user"
    }.freeze

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
      uri = URI("#{BASE_URL}/models/#{model}:streamGenerateContent")
      uri.query = URI.encode_www_form(alt: "sse")
      uri
    end

    def gemini_http_client(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT
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
          thinkingConfig: { thinkingBudget: THINKING_BUDGET },
          maxOutputTokens: MAX_OUTPUT_TOKENS
        }
      }
    end

    def format_gemini_message(message)
      message = message.symbolize_keys
      role = normalize_gemini_role(message[:role])

      {
        role: role,
        parts: [ { text: message[:content].to_s } ]
      }
    end

    def normalize_gemini_role(role)
      ROLE_MAPPING[role.to_s] || role.to_s
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

    def log_text_extraction(text, context: "")
      preview = text[0..LOG_TEXT_PREVIEW_LENGTH]
      Rails.logger.debug "[Gemini] テキスト抽出#{context}: #{preview}..."
    end

    def log_payload_keys_once(payload, logged)
      return logged if logged || !payload.is_a?(Hash)

      Rails.logger.info "[Gemini] ペイロードキー: #{payload.keys}"
      true
    end

    def process_gemini_chunk(chunk, state)
      log_first_chunk_timing(state)
      log_chunk_received(chunk, state)

      update_buffers(chunk, state)
      lines = extract_lines_from_buffer(state)

      lines.each do |line|
        process_line(line, state) { |text| yield text }
      end
    end

    def log_first_chunk_timing(state)
      return unless state[:chunk_count].zero?

      first_chunk_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      delta = (first_chunk_at - state[:request_started_at]).round(3)
      Rails.logger.info "[Gemini] 初回チャンクまでの時間=#{delta}s t=#{first_chunk_at}"
    end

    def log_chunk_received(chunk, state)
      state[:chunk_count] += 1
      timestamp = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      Rails.logger.info "[Gemini] チャンク##{state[:chunk_count]} (#{chunk.bytesize}バイト) t=#{timestamp}"
    end

    def update_buffers(chunk, state)
      state[:raw_body] << chunk
      state[:line_buffer] << chunk
    end

    def extract_lines_from_buffer(state)
      lines = state[:line_buffer].split("\n", -1)
      state[:line_buffer] = lines.pop || ""
      lines.map { |line| line.chomp("\r") }
    end

    def process_line(line, state)
      if line.strip.empty?
        emit_accumulated_sse_data(state) { |text| yield text }
        return
      end

      accumulate_sse_data(line, state)
    end

    def emit_accumulated_sse_data(state)
      state[:logged_payload_keys] = emit_sse_payload!(state[:sse_data], state[:logged_payload_keys]) do |text|
        state[:emitted] = true
        log_text_extraction(text)
        yield text
      end
    end

    def accumulate_sse_data(line, state)
      line = line.strip
      return if line.start_with?(":")
      return unless line.start_with?("data:")

      data = line.sub(/\Adata:\s*/, "")
      return if data == "[DONE]"

      state[:sse_data] << "\n" unless state[:sse_data].empty?
      state[:sse_data] << data
    end

    def finalize_gemini_stream(state)
      append_remaining_buffer_to_sse(state)
      emit_final_sse_data(state) { |text| yield text }

      return if state[:emitted]

      emit_fallback_payloads(state) { |text| yield text }
    end

    def append_remaining_buffer_to_sse(state)
      return if state[:line_buffer].strip.empty?

      state[:sse_data] << "\n" unless state[:sse_data].empty?
      state[:sse_data] << state[:line_buffer].strip
    end

    def emit_final_sse_data(state)
      state[:logged_payload_keys] = emit_sse_payload!(state[:sse_data], state[:logged_payload_keys]) do |text|
        state[:emitted] = true
        log_text_extraction(text)
        yield text
      end
    end

    def emit_fallback_payloads(state)
      parse_gemini_payloads(state[:raw_body]).each do |payload|
        text = extract_gemini_text(payload)

        if text.blank?
          state[:logged_payload_keys] = log_payload_keys_once(payload, state[:logged_payload_keys])
          next
        end

        log_text_extraction(text, context: "(後処理)")
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
          logged_payload_keys = log_payload_keys_once(item, logged_payload_keys)
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

      candidates = payload["candidates"] || payload.dig("response", "candidates")
      return nil unless candidates.is_a?(Array)

      texts = extract_texts_from_candidates(candidates)
      texts.empty? ? nil : texts.join
    end

    def extract_texts_from_candidates(candidates)
      candidates.flat_map do |candidate|
        parts = candidate.dig("content", "parts")
        next [] unless parts.is_a?(Array)

        parts.filter_map { |part| part["text"] }
      end
    end
  end
end
