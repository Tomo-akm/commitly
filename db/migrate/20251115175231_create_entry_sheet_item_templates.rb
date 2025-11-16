class CreateEntrySheetItemTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :entry_sheet_item_templates do |t|
      t.references :user, null: false, foreign_key: true
      t.string :tag, null: false
      t.string :title, null: false
      t.text :content, null: false

      t.timestamps
    end

    add_index :entry_sheet_item_templates, [ :user_id, :tag ]
  end
end
