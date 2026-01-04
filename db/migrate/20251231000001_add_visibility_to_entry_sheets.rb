class AddVisibilityToEntrySheets < ActiveRecord::Migration[8.1]
  def change
    add_column :entry_sheets, :visibility, :integer, default: 0, null: false
    add_index :entry_sheets, :visibility
  end
end
