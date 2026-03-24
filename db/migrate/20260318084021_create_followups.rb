class CreateFollowups < ActiveRecord::Migration[8.1]
  def change
    create_table :followups do |t|
      t.references :contact, null: false, foreign_key: true
      t.datetime :scheduled_at
      t.references :draft, foreign_key: true, null: true
      t.integer :status, default: 0, null: false
      t.integer :delay_days
      t.integer :sequence_number

      t.timestamps
    end
    add_index :followups, :status
    add_index :followups, :scheduled_at
  end
end
