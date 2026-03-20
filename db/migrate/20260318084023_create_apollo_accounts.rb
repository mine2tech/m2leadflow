class CreateApolloAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :apollo_accounts do |t|
      t.string :email, null: false
      t.text :credentials_encrypted
      t.integer :credits_remaining, default: 0
      t.date :reset_date
      t.integer :status, default: 0, null: false

      t.timestamps
    end
    add_index :apollo_accounts, :email, unique: true
    add_index :apollo_accounts, :status
  end
end
