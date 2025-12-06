class RecreateModelsForSdk < ActiveRecord::Migration[8.1]
  def change
    create_table :models do |t|
      t.timestamps

      t.string :model_id, null: false
      t.string :name, null: false
      t.string :provider, null: false
    end

    add_index :models, [ :provider, :model_id ], unique: true
  end
end
