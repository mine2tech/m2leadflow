class AddThreadAndSequenceToDrafts < ActiveRecord::Migration[8.1]
  def change
    add_column :drafts, :email_thread_id, :bigint
    add_column :drafts, :sequence_number, :integer
    add_index :drafts, :email_thread_id
    add_foreign_key :drafts, :email_threads
  end
end
