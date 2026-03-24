class RemoveViewerRoleAndRenameApproved < ActiveRecord::Migration[8.1]
  def up
    # Convert any viewer users (role=0) to editor (role=1)
    execute "UPDATE users SET role = 1 WHERE role = 0"
    # Change default from 0 (viewer) to 1 (editor)
    change_column_default :users, :role, from: 0, to: 1

    # Rename draft_approved activities to draft_reviewed
    execute "UPDATE activities SET action = 'draft_reviewed' WHERE action = 'draft_approved'"
  end

  def down
    change_column_default :users, :role, from: 1, to: 0
    execute "UPDATE activities SET action = 'draft_approved' WHERE action = 'draft_reviewed'"
  end
end
