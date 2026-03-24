class AddPhoneToContactsAndMakeEmailOptional < ActiveRecord::Migration[8.1]
  def change
    add_column :contacts, :phone, :string
    change_column_null :contacts, :email, true

    # Replace unconditional unique index with conditional one
    remove_index :contacts, :email
    add_index :contacts, :email, unique: true, where: "email IS NOT NULL AND email != ''"
  end
end
