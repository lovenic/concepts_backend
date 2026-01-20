class Concept < ApplicationRecord
  belongs_to :category
  belongs_to :user

  has_many :pins, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :pinned_users, through: :pins, source: :user
  has_many :liked_users, through: :likes, source: :user

  validates :title, presence: true, length: { minimum: 1, maximum: 200 }
  validates :body, presence: true

  scope :by_category, ->(category_id) { where(category_id: category_id) }
  scope :newest, -> { order(created_at: :desc) }
  scope :hot, ->(period = :daily) {
    start_time = case period.to_sym
                 when :daily
                   Time.current.beginning_of_day
                 when :weekly
                   Time.current.beginning_of_week
                 when :monthly
                   Time.current.beginning_of_month
                 else
                   Time.current.beginning_of_day
                 end

    select("concepts.*, 
            COALESCE(COUNT(DISTINCT CASE WHEN likes.created_at >= '#{start_time}' THEN likes.id END), 0) +
            COALESCE(COUNT(DISTINCT CASE WHEN pins.created_at >= '#{start_time}' THEN pins.id END), 0) AS engagement_score")
      .left_joins(:likes, :pins)
      .group("concepts.id")
      .order("engagement_score DESC, concepts.created_at DESC")
  }

  def likes_count
    likes.count
  end

  def pins_count
    pins.count
  end

  def liked_by?(user)
    return false unless user
    likes.exists?(user_id: user.id)
  end

  def pinned_by?(user)
    return false unless user
    pins.exists?(user_id: user.id)
  end
end
