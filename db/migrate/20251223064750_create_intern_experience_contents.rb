class CreateInternExperienceContents < ActiveRecord::Migration[8.1]
  def change
    create_table :intern_experience_contents do |t|
      t.string :company_name, null: false, limit: 100
      t.text :content, null: false, limit: 5000

      t.timestamps
    end

    add_index :intern_experience_contents, :company_name
  end
end
