module API
  class UsersController < BaseController
    def update_timezone
      timezone = params[:timezone]
      
      unless timezone.present?
        return render json: { error: "Timezone is required", code: "MISSING_TIMEZONE" }, status: :bad_request
      end

      # Validate timezone
      begin
        Time.zone = timezone
      rescue ArgumentError
        return render json: { error: "Invalid timezone", code: "INVALID_TIMEZONE" }, status: :bad_request
      end

      current_user.update!(timezone: timezone)

      render json: {
        success: true,
        user: {
          id: current_user.id,
          timezone: current_user.timezone
        }
      }, status: :ok
    rescue StandardError => e
      Rails.logger.error "UsersController#update_timezone error: #{e.message}"
      render json: { error: "Failed to update timezone", code: "UPDATE_ERROR", details: { message: e.message } }, status: :unprocessable_entity
    end
  end
end
