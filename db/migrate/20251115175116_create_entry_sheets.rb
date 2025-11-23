class CreateEntrySheets < ActiveRecord::Migration[8.1]
  def change
    create_table :entry_sheets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :company_name, null: false
      t.datetime :deadline
      t.integer :status, null: false, default: 0
      t.datetime :submitted_at

      t.timestamps
    end

    add_index :entry_sheets, [ :user_id, :company_name ]
    add_index :entry_sheets, [ :user_id, :status ]
    add_index :entry_sheets, :deadline
  end
end
