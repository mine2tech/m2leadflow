class AddUserIdToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :user_id, :bigint
    add_foreign_key :tasks, :users
  end
end
