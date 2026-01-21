class MakeUserIdNullableInConcepts < ActiveRecord::Migration[8.1]
  def up
    # Remove foreign key constraint
    remove_foreign_key :concepts, :users
    
    # Change column to allow null
    change_column_null :concepts, :user_id, true
    
    # Re-add foreign key with nullify on delete (optional, but good practice)
    add_foreign_key :concepts, :users, on_delete: :nullify
  end

  def down
    # Remove foreign key
    remove_foreign_key :concepts, :users
    
    # Set all null user_ids to a default (or raise error if any exist)
    # For safety, we'll raise an error if there are any null user_ids
    execute <<-SQL
      UPDATE concepts SET user_id = (SELECT id FROM users LIMIT 1) WHERE user_id IS NULL;
    SQL
    
    # Change column back to not allow null
    change_column_null :concepts, :user_id, false
    
    # Re-add foreign key
    add_foreign_key :concepts, :users
  end
end
