class DailyNotificationJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    # Double-check it's still 10 AM in user's timezone
    user_time = Time.current.in_time_zone(user.timezone)
    unless user_time.hour == 10 && user_time.min < 5
      Rails.logger.warn "DailyNotificationJob: Skipping user #{user_id} - not 10 AM in their timezone"
      return
    end

    # Only send to subscribed users
    unless user.is_subscribed?
      Rails.logger.info "DailyNotificationJob: Skipping user #{user_id} - not subscribed"
      return
    end

    # Skip users without push token
    unless user.expo_push_token.present?
      Rails.logger.info "DailyNotificationJob: Skipping user #{user_id} - no push token"
      return
    end

    # Send push notification
    begin
      ExpoPushService.send(
        token: user.expo_push_token,
        title: "Check out what's interesting in concepts today!",
        body: "Discover new ideas and concepts that might interest you 🌟",
        data: { type: "daily_concept_reminder" }
      )
      Rails.logger.info "DailyNotificationJob: Sent daily reminder push notification to user #{user.id}"
    rescue => e
      Rails.logger.error "DailyNotificationJob: Failed to send push notification to user #{user.id}: #{e.message}"
      raise
    end
  end
end
