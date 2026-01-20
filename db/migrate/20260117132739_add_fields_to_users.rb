class AddFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :timezone, :string, default: "UTC", null: false
    add_column :users, :is_subscribed, :boolean, default: false, null: false
    add_index :users, :is_subscribed unless index_exists?(:users, :is_subscribed)
  end
end
