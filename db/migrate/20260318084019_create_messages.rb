class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :email_thread, null: false, foreign_key: true
      t.integer :direction, null: false
      t.string :subject
      t.text :body
      t.string :gmail_message_id

      t.timestamps
    end
    add_index :messages, :gmail_message_id
    add_index :messages, :direction
  end
end
