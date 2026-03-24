class CreateEmailThreads < ActiveRecord::Migration[8.1]
  def change
    create_table :email_threads do |t|
      t.references :contact, null: false, foreign_key: true
      t.string :external_thread_id

      t.timestamps
    end
    add_index :email_threads, :external_thread_id
  end
end
