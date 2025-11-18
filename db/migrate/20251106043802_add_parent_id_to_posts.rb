class AddParentIdToPosts < ActiveRecord::Migration[8.1]
  def change
    add_reference :posts, :parent, foreign_key: { to_table: :posts }
  end
end
