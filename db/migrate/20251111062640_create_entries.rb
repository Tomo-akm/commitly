class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :room, null: false, foreign_key: true
      t.datetime :last_read_at

      t.timestamps
    end

    # ユーザーが同じルームに複数回参加しないようにする
    add_index :entries, [ :user_id, :room_id ], unique: true
  end
end
