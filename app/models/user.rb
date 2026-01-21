class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable
  include DeviseTokenAuth::Concerns::User
  include UserTimeManagement

  has_many :concepts, dependent: :nullify
  has_many :pins, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :pinned_concepts, through: :pins, source: :concept
  has_many :liked_concepts, through: :likes, source: :concept

  validates :timezone, presence: true
  validates :email, presence: true, if: -> { provider == 'email' }
  validates :expo_push_token, length: { maximum: 500 }, allow_nil: true

  scope :subscribed, -> { where(is_subscribed: true) }

  after_create_commit :send_welcome_email_if_needed

  DAILY_CONCEPT_LIMIT = 3

  def can_generate_concept?
    reset_daily_concepts_count_if_needed!
    daily_concepts_count < DAILY_CONCEPT_LIMIT
  end

  def increment_daily_concepts_count!
    # Use transaction with row-level locking to prevent race conditions
    transaction do
      # Reload with lock to prevent concurrent modifications
      lock!
      reset_daily_concepts_count_if_needed!
      
      # Double-check limit after lock to prevent race condition
      if daily_concepts_count >= DAILY_CONCEPT_LIMIT
        raise ActiveRecord::RecordInvalid.new(self.tap { |u| u.errors.add(:base, "Daily limit exceeded") })
      end
      
      increment!(:daily_concepts_count)
      touch(:last_concept_generated_at)
    end
  end

  def reset_daily_concepts_count_if_needed!
    # Get beginning of day in user's timezone
    user_day_start = user_beginning_of_day
    
    # Convert last_concept_generated_at to user's timezone for comparison
    last_generated_in_user_tz = last_concept_generated_at ? time_in_user_timezone(last_concept_generated_at) : nil
    
    # Reset if last generation was before today in user's timezone
    return unless last_generated_in_user_tz.nil? || last_generated_in_user_tz < user_day_start

    update_columns(
      daily_concepts_count: 0,
      last_concept_generated_at: nil
    )
  end

  def remaining_daily_concepts
    reset_daily_concepts_count_if_needed!
    [DAILY_CONCEPT_LIMIT - daily_concepts_count, 0].max
  end

  private

  def send_welcome_email_if_needed
    # Only send welcome email for users with real email addresses (not placeholder)
    return unless email.present?
    # Skip placeholder emails (like apple_xxx@concepts.local or apple_xxx@backend.local)
    return if email.include?("@#{Rails.application.class.module_parent_name.downcase}.local")

    Rails.logger.info "Sending welcome email to #{email} (provider: #{provider})"
    begin
      UserMailer.welcome_email(self).deliver_now
      Rails.logger.info "Welcome email sent successfully to #{email}"
    rescue => e
      Rails.logger.error "Failed to send welcome email: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end
