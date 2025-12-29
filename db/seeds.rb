# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# 追加したい seed ファイルの一覧
seed_files = []

seed_files.each do |file|
  seed_path = Rails.root.join("db", "seeds", file)
  load(seed_path) if File.exist?(seed_path)
end
