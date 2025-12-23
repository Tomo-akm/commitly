class AddEventNameAndDurationToInternExperienceContents < ActiveRecord::Migration[8.1]
  def change
    add_column :intern_experience_contents, :event_name, :string
    add_column :intern_experience_contents, :duration, :string
  end
end
