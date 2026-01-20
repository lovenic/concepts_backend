class CreatePins < ActiveRecord::Migration[8.1]
  def change
    create_table :pins do |t|
      t.references :user, null: false, foreign_key: true
      t.references :concept, null: false, foreign_key: true

      t.timestamps
    end

    add_index :pins, [:user_id, :concept_id], unique: true
    add_index :pins, :created_at
  end
end
