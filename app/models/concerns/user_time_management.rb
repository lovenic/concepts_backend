module UserTimeManagement
  extend ActiveSupport::Concern

  def user_timezone
    timezone || "UTC"
  end

  def user_current_time
    Time.current.in_time_zone(user_timezone)
  end

  def user_beginning_of_day
    user_current_time.beginning_of_day
  end

  def time_in_user_timezone(time = Time.current)
    time.in_time_zone(user_timezone)
  end
end
