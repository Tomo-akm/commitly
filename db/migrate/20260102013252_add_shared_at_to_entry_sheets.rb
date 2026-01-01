class AddSharedAtToEntrySheets < ActiveRecord::Migration[8.1]
  def up
    add_column :entry_sheets, :shared_at, :datetime
    add_index :entry_sheets, :shared_at

    execute <<~SQL.squish
      UPDATE entry_sheets
      SET shared_at = updated_at
      WHERE visibility = 1 AND shared_at IS NULL
    SQL
  end

  def down
    remove_index :entry_sheets, :shared_at
    remove_column :entry_sheets, :shared_at
  end
end
