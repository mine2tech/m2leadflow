class AddCalendarFieldsToMeetings < ActiveRecord::Migration[8.1]
  def change
    add_column :meetings, :calendar_event_id, :string
    add_column :meetings, :duration_minutes, :integer, default: 30
    add_column :meetings, :agenda, :text
    add_column :meetings, :location, :string
    add_column :meetings, :invitees, :text, array: true, default: []

    add_index :meetings, :calendar_event_id, unique: true
  end
end
