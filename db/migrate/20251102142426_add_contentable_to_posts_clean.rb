class AddContentableToPostsClean < ActiveRecord::Migration[8.1]
  def change
    # general_contents テーブル作成
    create_table :general_contents do |t|
      t.text :content, null: false
      t.timestamps
    end

    # job_hunting_contents テーブル作成
    create_table :job_hunting_contents do |t|
      t.string :company_name, null: false
      t.integer :selection_stage, null: false
      t.integer :result, null: false
      t.text :content, null: false
      t.timestamps
    end

    # インデックス追加
    add_index :job_hunting_contents, :company_name
    add_index :job_hunting_contents, :selection_stage
    add_index :job_hunting_contents, :result

    # posts テーブルに contentable 追加
    add_reference :posts, :contentable, polymorphic: true, null: false, index: true

    # 古い content カラムを削除
    remove_column :posts, :content, :text
  end
end
