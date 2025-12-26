# frozen_string_literal: true

class AddAccountIdToUsers < ActiveRecord::Migration[7.0]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    add_column :users, :account_id, :string, limit: 20
    add_index :users, :account_id, unique: true

    MigrationUser.reset_column_information
    MigrationUser.find_each do |user|
      user.update_columns(account_id: generate_unique_account_id)
    end

    change_column_null :users, :account_id, false
  end

  def down
    remove_index :users, :account_id
    remove_column :users, :account_id
  end

  private

  def generate_unique_account_id
    loop do
      account_id = SecureRandom.alphanumeric(12)
      return account_id unless MigrationUser.exists?(account_id: account_id)
    end
  end
end
