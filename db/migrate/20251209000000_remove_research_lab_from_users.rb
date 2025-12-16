class RemoveResearchLabFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :research_lab, :string
  end
end
