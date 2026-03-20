class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :domain, null: false
      t.integer :status, default: 0, null: false
      t.text :notes

      t.timestamps
    end
    add_index :companies, :domain, unique: true
    add_index :companies, :status
  end
end
