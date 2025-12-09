class AddCustomColumnsToChats < ActiveRecord::Migration[8.1]
  def change
    add_reference :chats, :user, null: false, foreign_key: true
    add_reference :chats, :chattable, polymorphic: true, null: true
    add_column :chats, :title, :string

    add_index :chats, [ :user_id, :created_at ]
  end
end
