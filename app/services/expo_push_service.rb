require "httparty"

class ExpoPushService
  EXPO_URL = "https://exp.host/--/api/v2/push/send"

  def self.send(token:, title:, body:, data: {})
    message = {
      to: token,
      sound: "default",
      title: title,
      body: body,
      data: data
    }

    response = HTTParty.post(
      EXPO_URL,
      headers: {
        "Accept" => "application/json",
        "Accept-Encoding" => "gzip, deflate",
        "Content-Type" => "application/json"
      },
      body: message.to_json
    )

    Rails.logger.info("Expo push response: #{response.code} #{response.body}")
    response
  end
end
