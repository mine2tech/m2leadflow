class CreateGmailAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :gmail_accounts do |t|
      t.string :email, null: false
      t.text :access_token_ciphertext
      t.text :refresh_token_ciphertext
      t.datetime :token_expires_at
      t.integer :status, default: 0, null: false

      t.timestamps
    end
    add_index :gmail_accounts, :email, unique: true
  end
end
