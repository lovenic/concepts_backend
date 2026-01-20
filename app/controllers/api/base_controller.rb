module API
  class BaseController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
    rescue_from StandardError, with: :handle_standard_error

    private

    def handle_not_found(exception)
      Rails.logger.error "Record not found: #{exception.message}"
      render json: {
        error: "Resource not found",
        code: "NOT_FOUND",
        details: { message: exception.message }
      }, status: :not_found
    end

    def handle_validation_error(exception)
      Rails.logger.error "Validation error: #{exception.message}"
      render json: {
        error: "Validation failed",
        code: "VALIDATION_ERROR",
        details: {
          message: exception.message,
          errors: exception.record&.errors&.full_messages
        }
      }, status: :unprocessable_entity
    end

    def handle_parameter_missing(exception)
      Rails.logger.error "Parameter missing: #{exception.message}"
      render json: {
        error: "Missing required parameter",
        code: "PARAMETER_MISSING",
        details: { message: exception.message, param: exception.param }
      }, status: :bad_request
    end

    def handle_standard_error(exception)
      Rails.logger.error "Standard error: #{exception.class} - #{exception.message}"
      Rails.logger.error exception.backtrace.join("\n")
      
      render json: {
        error: "An error occurred",
        code: "INTERNAL_ERROR",
        details: {
          message: Rails.env.development? ? exception.message : "Please try again later"
        }
      }, status: :internal_server_error
    end
  end
end
