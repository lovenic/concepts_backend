class Category < ApplicationRecord
  has_ancestry

  has_many :concepts, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :roots, -> { where(ancestry: nil) }

  def descendant_ids
    descendants.pluck(:id)
  end
end
