module API
  class AccountsController < ApplicationController
    skip_after_action :update_auth_header, only: [ :destroy ]

    def destroy
      user = current_user
      user_email = user.email

      sign_out(user)

      ActiveRecord::Base.transaction do
        user.pins.destroy_all
        user.likes.destroy_all
        user.concepts.destroy_all
        user.destroy!
      end

      render json: { message: "Profile deleted successfully" }, status: :ok
    rescue StandardError => e
      render json: { error: "Failed to delete profile", details: e.message }, status: :unprocessable_entity
    end
  end
end
