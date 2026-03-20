class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :task_type, null: false
      t.jsonb :payload, default: {}
      t.integer :status, default: 0, null: false
      t.integer :attempts, default: 0, null: false
      t.integer :max_attempts, default: 3, null: false
      t.jsonb :result, default: {}
      t.text :error

      t.timestamps
    end
    add_index :tasks, :status
    add_index :tasks, :task_type
    add_index :tasks, [:status, :created_at]
  end
end
