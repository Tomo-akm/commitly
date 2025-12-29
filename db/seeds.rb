# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# 追加したい seed ファイルの一覧
seed_files = []

seed_files.each do |file|
  seed_path = Rails.root.join("db", "seeds", file)
  load(seed_path) if File.exist?(seed_path)
end

# 管理者ユーザーの作成（開発環境のみ）
if Rails.env.development?
  admin = User.find_or_initialize_by(email: "admin@example.com")
  unless admin.persisted?
    admin.assign_attributes(
      name: "管理者",
      password: "password",
      password_confirmation: "password",
      account_id: "admin",
      internship_count: 0,
      admin: true
    )
    admin.save!
    puts "管理者ユーザーを作成しました: #{admin.email}"
  else
    admin.update!(admin: true)
    puts "既存ユーザーを管理者に設定しました: #{admin.email}"
  end
end
