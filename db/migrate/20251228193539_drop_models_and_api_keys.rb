class DropModelsAndApiKeys < ActiveRecord::Migration[8.1]
  def change
    drop_table :models, if_exists: true do |t|
      t.string :model_id, null: false
      t.string :name, null: false
      t.string :provider, null: false
      t.timestamps
    end

    drop_table :api_keys, if_exists: true do |t|
      t.text :api_key, null: false
      t.string :provider, null: false
      t.bigint :user_id, null: false
      t.timestamps
    end
  end
end
