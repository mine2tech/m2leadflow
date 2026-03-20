class AddMissingIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :drafts, [:contact_id, :status], name: "index_drafts_on_contact_id_and_status"
    add_index :drafts, [:contact_id, :sequence_number], name: "index_drafts_on_contact_id_and_sequence"
    add_index :followups, [:contact_id, :sequence_number, :status], name: "index_followups_on_contact_seq_status"
    add_index :meetings, [:contact_id, :status], name: "index_meetings_on_contact_id_and_status"
  end
end
