class DailyNotificationSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    # Get distinct timezones that have 10 AM right now
    eligible_timezones = get_eligible_timezones

    Rails.logger.info "DailyNotificationSchedulerJob: Found #{eligible_timezones.count} eligible timezones at 10 AM"

    # Find users with eligible timezones and schedule notifications
    User.where(timezone: eligible_timezones).find_each do |user|
      # Only send to subscribed users
      next unless user.is_subscribed?

      # Skip users without push token
      next unless user.expo_push_token.present?

      # Schedule individual notification job
      DailyNotificationJob.perform_later(user.id)
      Rails.logger.info "DailyNotificationSchedulerJob: Scheduled notification for user #{user.id}"
    end
  end

  private

  def get_eligible_timezones
    User.where.not(timezone: [nil, ""])
        .distinct
        .pluck(:timezone)
        .select do |timezone|
          user_time = Time.current.in_time_zone(timezone)
          user_time.hour == 10 && user_time.min < 5 # Within first 5 minutes of 10 AM
        end
  end
end
