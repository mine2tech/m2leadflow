class CreateDrafts < ActiveRecord::Migration[8.1]
  def change
    create_table :drafts do |t|
      t.references :contact, null: false, foreign_key: true
      t.string :subject
      t.text :body
      t.integer :status, default: 0, null: false

      t.timestamps
    end
    add_index :drafts, :status
  end
end
