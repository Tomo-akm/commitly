class DropRubyLlmRelatedTables < ActiveRecord::Migration[8.1]
  def change
    # messages から不要カラムを削除
    remove_column :messages, :tool_call_id, if_exists: true
    remove_column :messages, :content_raw, if_exists: true
    remove_column :messages, :input_tokens, if_exists: true
    remove_column :messages, :output_tokens, if_exists: true
    remove_column :messages, :cache_creation_tokens, if_exists: true
    remove_column :messages, :cached_tokens, if_exists: true

    # messages → tool_calls / models への外部キー削除
    remove_foreign_key :messages, :tool_calls if foreign_key_exists?(:messages, :tool_calls)
    remove_foreign_key :messages, :models if foreign_key_exists?(:messages, :models)

    # tool_calls → messages への外部キー削除
    remove_foreign_key :tool_calls, :messages if foreign_key_exists?(:tool_calls, :messages)

    # tool_calls テーブル削除
    drop_table :tool_calls, if_exists: true

    # chats → models への外部キー削除
    remove_foreign_key :chats, :models if foreign_key_exists?(:chats, :models)
    remove_column :chats, :model_id, if_exists: true

    # models テーブル削除
    drop_table :models, if_exists: true

    # ActiveStorage 関連テーブル削除
    drop_table :active_storage_attachments, if_exists: true
    drop_table :active_storage_variant_records, if_exists: true
    drop_table :active_storage_blobs, if_exists: true
  end
end
