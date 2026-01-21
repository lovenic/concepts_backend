module API
  class AccountsController < ApplicationController
    skip_after_action :update_auth_header, only: [ :destroy ]

    def destroy
      user = current_user

      sign_out(user)

      ActiveRecord::Base.transaction do
        # Delete pins and likes
        user.pins.destroy_all
        user.likes.destroy_all
        
        # Nullify user_id in concepts instead of deleting them
        user.concepts.update_all(user_id: nil)
        
        # Delete the user
        user.destroy!
      end

      render json: { message: "Profile deleted successfully" }, status: :ok
    rescue StandardError => e
      render json: { error: "Failed to delete profile", details: e.message }, status: :unprocessable_entity
    end
  end
end
