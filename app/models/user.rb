class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable
  include DeviseTokenAuth::Concerns::User
  include UserTimeManagement

  has_many :concepts, dependent: :destroy
  has_many :pins, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :pinned_concepts, through: :pins, source: :concept
  has_many :liked_concepts, through: :likes, source: :concept

  validates :timezone, presence: true
  validates :email, presence: true, if: -> { provider == 'email' }

  scope :subscribed, -> { where(is_subscribed: true) }

  DAILY_CONCEPT_LIMIT = 3

  def can_generate_concept?
    reset_daily_concepts_count_if_needed!
    daily_concepts_count < DAILY_CONCEPT_LIMIT
  end

  def increment_daily_concepts_count!
    reset_daily_concepts_count_if_needed!
    increment!(:daily_concepts_count)
    touch(:last_concept_generated_at)
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
end
