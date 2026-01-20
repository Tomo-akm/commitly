# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# 追加したい seed ファイルの一覧
# 順番が重要：依存関係のあるファイルは後に配置
seed_files = [
  "demo_users.rb",        # ユーザー作成（最初に実行）
  "demo_follows.rb",      # フォロー関係
  "demo_posts.rb",        # 投稿（つぶやき/就活記録/インターン）
  "demo_entry_sheets.rb", # ES・テンプレート
  "demo_interactions.rb", # ES共有投稿・リプライ・いいね
  "demo_dms.rb",          # DM
  "demo_achievements.rb"  # バッジ付与
]

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
