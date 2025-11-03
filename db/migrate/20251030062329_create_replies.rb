# frozen_string_literal: true

class CreateReplies < ActiveRecord::Migration[8.1]
  def change
    create_table :replies do |t|
      t.text :content
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :replies }, null: true

      t.timestamps
    end
  end
end
