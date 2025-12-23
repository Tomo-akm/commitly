class MigrateMessagesToDirectMessages < ActiveRecord::Migration[8.1]
  def up
    # DM用のmessagesテーブルが存在する場合のみ処理
    if table_exists?(:messages) && column_exists?(:messages, :room_id)
      # direct_messagesテーブルが存在しない場合は作成
      unless table_exists?(:direct_messages)
        create_table :direct_messages do |t|
          t.references :room, null: false, foreign_key: true
          t.references :user, null: false, foreign_key: true
          t.text :content, null: false

          t.timestamps
        end

        add_index :direct_messages, :created_at
      end

      # 既存データをコピー（messagesテーブルにroom_idカラムがある場合）
      execute <<-SQL
        INSERT INTO direct_messages (id, room_id, user_id, content, created_at, updated_at)
        SELECT id, room_id, user_id, content, created_at, updated_at
        FROM messages
        WHERE room_id IS NOT NULL
      SQL

      # シーケンスを更新
      execute <<-SQL
        SELECT setval('direct_messages_id_seq', COALESCE((SELECT MAX(id) FROM direct_messages), 1), true)
      SQL

      # 古いmessagesテーブルからDM関連データを削除
      execute "DELETE FROM messages WHERE room_id IS NOT NULL"
    end
  end

  def down
    # ロールバック処理
    if table_exists?(:direct_messages)
      execute <<-SQL
        INSERT INTO messages (id, room_id, user_id, content, created_at, updated_at)
        SELECT id, room_id, user_id, content, created_at, updated_at
        FROM direct_messages
      SQL

      drop_table :direct_messages
    end
  end
end
