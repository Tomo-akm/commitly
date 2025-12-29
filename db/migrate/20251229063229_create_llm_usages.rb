class CreateLlmUsages < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_usages do |t|
      t.timestamps

      t.references :user, null: false, foreign_key: true
      t.date :usage_date, null: false
      t.integer :count, null: false, default: 0
    end

    add_index :llm_usages, [ :user_id, :usage_date ], unique: true
  end
end
