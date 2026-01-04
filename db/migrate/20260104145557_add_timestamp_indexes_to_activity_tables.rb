class AddTimestampIndexesToActivityTables < ActiveRecord::Migration[8.1]
  def change
    # 実績判定で使用するタイムスタンプカラムにインデックスを追加
    # group_by_day のパフォーマンス改善
    add_index :posts, :created_at
    add_index :entry_sheets, :updated_at
    add_index :entry_sheet_item_templates, :created_at
    add_index :entry_sheet_item_templates, :updated_at
  end
end
