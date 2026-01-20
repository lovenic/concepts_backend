module API
  class SubscriptionsController < ApplicationController
    skip_before_action :authenticate_user!

    # POST /api/subscriptions
    def create
      return unauthorized! unless valid_webhook_auth?

      event = extract_event
      return render json: { error: "Missing event payload" }, status: :bad_request unless event

      user = User.find_by(uid: event["app_user_id"])
      return render json: { error: "User not found" }, status: :not_found unless user

      update_subscription_status(user, event)

      render json: { message: "Subscription status updated", event_type: event["type"] }, status: :ok
    end

    private

    def valid_webhook_auth?
      expected = ENV["RC_WEBHOOK_AUTH"]
      provided = request.headers["Authorization"]
      expected.blank? || provided == expected
    end

    def unauthorized!
      render json: { error: "Unauthorized" }, status: :unauthorized
    end

    def extract_event
      params[:event] || params["event"]
    end

    def update_subscription_status(user, event)
      event_type = event["type"]
      timestamp = event["event_timestamp_ms"]

      case event_type
      when "INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION", "SUBSCRIPTION_EXTENDED", "TEMPORARY_ENTITLEMENT_GRANT"
        user.is_subscribed = true
        user.last_subscribed_at = Time.at(timestamp.to_i / 1000) if timestamp
      when "CANCELLATION"
        if %w[UNSUBSCRIBE DEVELOPER_INITIATED PRICE_INCREASE].include?(event["cancel_reason"])
          user.is_subscribed = false
          user.last_unsubscribed_at = Time.at(timestamp.to_i / 1000) if timestamp
        end
      when "EXPIRATION"
        user.is_subscribed = false
        user.last_unsubscribed_at = Time.at(timestamp.to_i / 1000) if timestamp
      end

      user.save!
    end
  end
end
