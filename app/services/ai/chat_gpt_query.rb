module AI
  class ChatGPTQuery
    attr_reader :client, :prompt, :is_json

    MODEL = "gpt-4o-mini"
    ROLE = "user"
    TEMPERATURE = 1.4
    MAX_RETRIES = 3

    def initialize(prompt:, is_json: false)
      @client = OpenAI::Client.new
      @prompt = prompt
      @is_json = is_json
    end

    def call
      # circuit braker
      raise "Message is too long" if @prompt.length > 50000

      response = client.chat(
        parameters: {
          model: MODEL,
          messages: [ { role: ROLE, content: prompt } ], # Required.
          temperature: TEMPERATURE
        })

      retries = 0

      text_response = response.dig("choices", 0, "message", "content")
      if is_json
        parsed = JSON.parse(text_response)
        # Если это массив, преобразуем каждый элемент, иначе преобразуем сам объект
        text_response = if parsed.is_a?(Array)
          parsed.map { |item| item.is_a?(Hash) ? item.with_indifferent_access : item }
        else
          parsed.with_indifferent_access
        end
      end

      text_response
    rescue JSON::ParserError => e
      retries += 1
      if retries <= MAX_RETRIES
        Rails.logger.warn "ChatGPT JSON parse error, retrying (#{retries}/#{MAX_RETRIES}): #{e.message}"
        retry
      else
        Rails.logger.error "All ChatGPT JSON parse retries failed"
        raise "Failed to parse AI response after #{MAX_RETRIES} attempts"
      end
    rescue StandardError => e
      Rails.logger.error "ChatGPT API error: #{e.message}"
      raise "AI service temporarily unavailable. Please try again later."
    end
  end
end
