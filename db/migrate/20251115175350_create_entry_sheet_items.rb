class CreateEntrySheetItems < ActiveRecord::Migration[8.1]
  def change
    create_table :entry_sheet_items do |t|
      t.references :entry_sheet, null: false, foreign_key: true
      t.references :entry_sheet_item_template, null: true, foreign_key: true
      t.text :title, null: false
      t.text :content, null: false
      t.integer :char_limit
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :entry_sheet_items, [ :entry_sheet_id, :position ]
  end
end
