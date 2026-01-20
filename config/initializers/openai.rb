OpenAI.configure do |config|
  config.access_token = Rails.application.credentials.config.dig(:open_ai, :access_token)
end
