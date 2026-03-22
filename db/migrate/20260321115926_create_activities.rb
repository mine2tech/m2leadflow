class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.references :trackable, polymorphic: true, null: false
      t.references :user, foreign_key: true
      t.string :action, null: false
      t.jsonb :metadata, default: {}
      t.timestamps
    end
    add_index :activities, [:trackable_type, :trackable_id, :created_at], name: "index_activities_on_trackable_and_created_at"
  end
end
