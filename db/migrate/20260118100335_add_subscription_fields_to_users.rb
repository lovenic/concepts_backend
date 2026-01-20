class AddSubscriptionFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_subscribed_at, :datetime
    add_column :users, :last_unsubscribed_at, :datetime
    
    add_index :users, :is_subscribed unless index_exists?(:users, :is_subscribed)
  end
end
