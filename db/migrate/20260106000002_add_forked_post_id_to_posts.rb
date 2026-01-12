class AddForkedPostIdToPosts < ActiveRecord::Migration[8.1]
  def change
    add_reference :posts, :forked_post, foreign_key: { to_table: :posts }, null: true, index: true
  end
end
