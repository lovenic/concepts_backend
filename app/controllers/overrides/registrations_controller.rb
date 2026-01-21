class Overrides::RegistrationsController < DeviseTokenAuth::RegistrationsController
  after_action :send_welcome_email_after_registration, only: [:create]

  def create
    Rails.logger.info "Overrides::RegistrationsController#create called"
    super do |resource|
      Rails.logger.info "RegistrationsController#create block called, resource persisted?: #{resource.persisted?}, provider: #{resource.provider}, email: #{resource.email}"
      
      if resource.persisted? && resource.provider == 'email' && resource.email.present?
        @registered_user = resource
        Rails.logger.info "User registered successfully: #{@registered_user.email}, sending welcome email immediately"
        
        # Send email immediately in the block
        begin
          UserMailer.welcome_email(@registered_user).deliver_now
          Rails.logger.info "Welcome email sent successfully to #{@registered_user.email}"
        rescue => e
          Rails.logger.error "Failed to send welcome email in block: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      else
        Rails.logger.warn "User not registered or not email provider - persisted?: #{resource.persisted?}, provider: #{resource.provider}, email present?: #{resource.email.present?}"
      end
    end
  end

  private

  def send_welcome_email_after_registration
    Rails.logger.info "send_welcome_email_after_registration called, @registered_user: #{@registered_user.inspect}, response status: #{response.status}"
    
    # Fallback: send email in after_action if not sent in block
    return unless @registered_user
    return unless @registered_user.provider == 'email'
    return unless @registered_user.email.present?

    Rails.logger.info "Sending welcome email in after_action to #{@registered_user.email}"
    begin
      UserMailer.welcome_email(@registered_user).deliver_now
      Rails.logger.info "Welcome email sent successfully in after_action to #{@registered_user.email}"
    rescue => e
      Rails.logger.error "Failed to send welcome email in after_action: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end
