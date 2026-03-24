class CreateCalendarAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :calendar_accounts do |t|
      t.string :email, null: false
      t.text :access_token_ciphertext
      t.text :refresh_token_ciphertext
      t.datetime :token_expires_at
      t.integer :status, default: 0, null: false

      t.timestamps
    end
    add_index :calendar_accounts, :email, unique: true
  end
end
