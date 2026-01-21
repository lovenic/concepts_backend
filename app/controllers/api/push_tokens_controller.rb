module API
  class PushTokensController < BaseController
    def create
      Rails.logger.info "PushTokensController#create called for user #{current_user.id}"
      Rails.logger.info "PushTokensController params: #{params.inspect}"
      
      expo_push_token = params[:expo_push_token] || params['expo_push_token']
      
      Rails.logger.info "PushTokensController: expo_push_token = #{expo_push_token.present? ? expo_push_token[0..50] + '...' : 'nil'}"
      
      unless expo_push_token.present?
        Rails.logger.error "PushTokensController: expo_push_token is missing"
        return render json: { error: "expo_push_token is required" }, status: :bad_request
      end

      # Validate token length to prevent DoS
      if expo_push_token.length > 500
        Rails.logger.error "PushTokensController: expo_push_token too long (#{expo_push_token.length} chars)"
        return render json: { error: "Invalid push token format" }, status: :bad_request
      end

      update_expo_push_token!(expo_push_token)

      head :ok
    end

    def destroy
      Rails.logger.info "PushTokensController#destroy called for user #{current_user.id}"
      
      if current_user.update(expo_push_token: nil)
        Rails.logger.info "PushTokensController: Deleted expo_push_token for user #{current_user.id}"
        head :ok
      else
        Rails.logger.error "PushTokensController: Failed to delete expo_push_token for user #{current_user.id}: #{current_user.errors.full_messages.join(', ')}"
        render json: { error: "Failed to delete push token" }, status: :unprocessable_entity
      end
    end

    private

    def update_expo_push_token!(expo_push_token)
      current_expo_push_token = current_user.expo_push_token

      Rails.logger.info "PushTokensController: Current token: #{current_expo_push_token.present? ? 'present' : 'nil'}, New token: #{expo_push_token.present? ? 'present' : 'nil'}"

      if current_expo_push_token != expo_push_token
        if current_user.update(expo_push_token: expo_push_token)
          Rails.logger.info "PushTokensController: Updated expo_push_token for user #{current_user.id}"
        else
          Rails.logger.error "PushTokensController: Failed to update expo_push_token for user #{current_user.id}: #{current_user.errors.full_messages.join(', ')}"
        end
      else
        Rails.logger.info "PushTokensController: Token unchanged, skipping update"
      end
    end
  end
end
