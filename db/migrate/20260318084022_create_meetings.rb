class CreateMeetings < ActiveRecord::Migration[8.1]
  def change
    create_table :meetings do |t|
      t.references :contact, null: false, foreign_key: true
      t.datetime :scheduled_at
      t.string :meeting_link
      t.text :notes
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
