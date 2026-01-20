class AddRateLimitFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :daily_concepts_count, :integer, default: 0, null: false
    add_column :users, :last_concept_generated_at, :datetime
  end
end
