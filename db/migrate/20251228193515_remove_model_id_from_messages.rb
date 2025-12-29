class RemoveModelIdFromMessages < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :messages, :models if foreign_key_exists?(:messages, :models)
    remove_column :messages, :model_id, :bigint if column_exists?(:messages, :model_id)
  end
end
