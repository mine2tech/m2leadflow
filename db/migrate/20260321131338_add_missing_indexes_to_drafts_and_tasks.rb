class AddMissingIndexesToDraftsAndTasks < ActiveRecord::Migration[8.1]
  def change
    add_index :drafts, :user_id
    add_index :tasks, :user_id
  end
end
