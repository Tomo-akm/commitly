class RecreateModelIdInMessages < ActiveRecord::Migration[8.1]
  def change
    remove_column :messages, :model_id, if_exists: true
    add_reference :messages, :model, foreign_key: true
  end
end
