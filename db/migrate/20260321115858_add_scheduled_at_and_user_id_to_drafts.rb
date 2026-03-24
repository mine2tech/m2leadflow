class AddScheduledAtAndUserIdToDrafts < ActiveRecord::Migration[8.1]
  def change
    add_column :drafts, :scheduled_at, :datetime
    add_column :drafts, :user_id, :bigint
    add_index :drafts, :scheduled_at
    add_foreign_key :drafts, :users
  end
end
