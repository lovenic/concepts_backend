class CreateConcepts < ActiveRecord::Migration[8.1]
  def change
    create_table :concepts do |t|
      t.string :title, null: false
      t.jsonb :body, null: false, default: {}
      t.references :category, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true

      t.timestamps
    end

    add_index :concepts, :created_at
  end
end
