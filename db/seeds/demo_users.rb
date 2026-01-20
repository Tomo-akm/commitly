# frozen_string_literal: true

# デモ用ユーザー5人の作成
puts "=== デモ用ユーザーを作成中 ==="

DEMO_USERS = [
  {
    name: "青山そら",
    email: "demo@example.com",
    account_id: "demo",
    graduation_year: 2026,
    internship_count: 0, # インターン投稿でカウント
    favorite_language: "Ruby",
    personal_message: "26卒エンジニア志望。Railsでプロダクト作ってます。",
    post_visibility: :everyone
  },
  {
    name: "佐藤ゆうき",
    email: "yuki@example.com",
    account_id: "yuki_dev",
    graduation_year: 2026,
    internship_count: 0, # インターン投稿でカウント
    favorite_language: "TypeScript",
    personal_message: "外資ITと国内メガベン中心に就活中。インターン経験多め。",
    post_visibility: :everyone
  },
  {
    name: "中村りく",
    email: "riku@example.com",
    account_id: "riku_26",
    graduation_year: 2026,
    internship_count: 0, # インターン投稿でカウント
    favorite_language: "Python",
    personal_message: "地方国立大からWeb系目指してます。ES書くの苦手...",
    post_visibility: :everyone
  },
  {
    name: "鈴木みく",
    email: "miku@example.com",
    account_id: "miku_anx",
    graduation_year: 2026,
    internship_count: 0, # インターン投稿でカウント
    favorite_language: "JavaScript",
    personal_message: "プログラミング始めて1年。就活不安だけど頑張る。",
    post_visibility: :everyone
  },
  {
    name: "高橋けんた",
    email: "kenta@example.com",
    account_id: "senpai_naitei",
    graduation_year: 2025,
    internship_count: 0, # インターン投稿でカウント
    favorite_language: "Go",
    personal_message: "25卒内定済み。後輩の就活サポートしてます。ESレビュー歓迎！",
    post_visibility: :everyone
  }
].freeze

DEMO_USERS.each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  unless user.persisted?
    user.assign_attributes(
      name: attrs[:name],
      password: "password",
      password_confirmation: "password",
      account_id: attrs[:account_id],
      graduation_year: attrs[:graduation_year],
      internship_count: attrs[:internship_count],
      favorite_language: attrs[:favorite_language],
      personal_message: attrs[:personal_message],
      post_visibility: attrs[:post_visibility]
    )
    user.save!
    puts "  作成: #{user.name} (@#{user.account_id})"
  else
    puts "  既存: #{user.name} (@#{user.account_id})"
  end
end

puts "=== デモ用ユーザー作成完了 ==="