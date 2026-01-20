class Pin < ApplicationRecord
  belongs_to :user
  belongs_to :concept

  validates :user_id, uniqueness: { scope: :concept_id, message: "has already pinned this concept" }
end
