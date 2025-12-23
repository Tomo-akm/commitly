class ChangeDurationToIntegerInInternContents < ActiveRecord::Migration[8.1]
  def change
    remove_column :intern_experience_contents, :duration, :string
    add_column :intern_experience_contents, :duration_days, :integer
  end
end
