class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name
      t.string :email, null: false
      t.string :role
      t.string :source
      t.float :confidence_score

      t.timestamps
    end
    add_index :contacts, :email, unique: true
  end
end
