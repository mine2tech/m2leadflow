class AddClassificationToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :classification, :integer
    add_column :messages, :classification_confidence, :float
  end
end
