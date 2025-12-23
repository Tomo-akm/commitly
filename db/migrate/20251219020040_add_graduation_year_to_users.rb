class AddGraduationYearToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :graduation_year, :integer
  end
end
