# frozen_string_literal: true

# デモ用投稿データの作成
puts "=== デモ用投稿を作成中 ==="

demo = User.find_by(account_id: "demo")
yuki = User.find_by(account_id: "yuki_dev")
riku = User.find_by(account_id: "riku_26")
miku = User.find_by(account_id: "miku_anx")
senpai = User.find_by(account_id: "senpai_naitei")

# 投稿作成用ヘルパー
def create_general_post(user, content, days_ago: 0)
  return if user.nil?

  general = GeneralContent.create!(content: content)
  post = Post.create!(
    user: user,
    contentable: general,
    created_at: days_ago.days.ago,
    updated_at: days_ago.days.ago
  )
  # ハッシュタグ抽出
  hashtags = content.scan(/#(\S+)/).flatten
  if hashtags.any?
    tags = Tag.find_or_create_by_names(hashtags)
    post.tags = tags
  end
  post
end

def create_job_hunting_post(user, company_name:, stage:, result:, content:, days_ago: 0)
  return if user.nil?

  job_hunting = JobHuntingContent.create!(
    company_name: company_name,
    selection_stage: stage,
    result: result,
    content: content
  )
  Post.create!(
    user: user,
    contentable: job_hunting,
    created_at: days_ago.days.ago,
    updated_at: days_ago.days.ago
  )
end

def create_intern_post(user, company_name:, event_name:, duration:, content:, days_ago: 0)
  return if user.nil?

  intern = InternExperienceContent.create!(
    company_name: company_name,
    event_name: event_name,
    duration_type: duration,
    content: content
  )
  Post.create!(
    user: user,
    contentable: intern,
    created_at: days_ago.days.ago,
    updated_at: days_ago.days.ago
  )
end

# ===========================================
# yuki（強者）の投稿 - 選考過程を全て記録
# ===========================================
puts "  yuki_devの投稿を作成中..."

# GlobalLogic: ES→1次→2次→最終→内定 のストーリー
create_job_hunting_post(yuki,
  company_name: "GlobalLogic",
  stage: :es,
  result: :passed,
  content: "外資IT本命。英語でES書いた。自分の強みを具体的なエピソードで書けた。",
  days_ago: 21)

create_job_hunting_post(yuki,
  company_name: "GlobalLogic",
  stage: :first_interview,
  result: :passed,
  content: "1次通過！英語面接だったけど、技術の話になると自然と話せた。",
  days_ago: 14)

create_job_hunting_post(yuki,
  company_name: "GlobalLogic",
  stage: :second_interview,
  result: :passed,
  content: "2次通過。ケース面接あり。フレームワーク暗記より構造化思考が大事。",
  days_ago: 7)

create_job_hunting_post(yuki,
  company_name: "GlobalLogic",
  stage: :final_interview,
  result: :passed,
  content: "内定！！外資IT第一志望だったので本当に嬉しい。インターンでの経験が活きた。",
  days_ago: 1)

# NorthStar Consulting: ES→1次→2次 進行中
create_job_hunting_post(yuki,
  company_name: "NorthStar Consulting",
  stage: :es,
  result: :passed,
  content: "コンサル併願。論理的思考力をアピール。",
  days_ago: 18)

create_job_hunting_post(yuki,
  company_name: "NorthStar Consulting",
  stage: :first_interview,
  result: :passed,
  content: "1次通過。フェルミ推定出た。日頃から数字で考える癖つけててよかった。",
  days_ago: 10)

create_job_hunting_post(yuki,
  company_name: "NorthStar Consulting",
  stage: :second_interview,
  result: :pending,
  content: "2次面接終わった。ケース面接、時間配分ミスった...結果待ち。",
  days_ago: 3)

# MerCoding: ES→1次 進行中
create_job_hunting_post(yuki,
  company_name: "MerCoding",
  stage: :es,
  result: :passed,
  content: "メガベン応募。ポートフォリオとGitHubのリンク載せた。",
  days_ago: 12)

create_job_hunting_post(yuki,
  company_name: "MerCoding",
  stage: :first_interview,
  result: :passed,
  content: "コーディングテスト通過。アルゴリズム問題2問45分。AtCoderやっててよかった。",
  days_ago: 5)

# インターン記録（5社分 = intern_participations_count: 5）
create_intern_post(yuki,
  company_name: "TechNova",
  event_name: "Summer Internship 2025",
  duration: :medium_term,
  content: "2週間でRailsアプリ作った。コードレビュー文化が神。毎日フィードバックもらえて成長実感。",
  days_ago: 180)

create_intern_post(yuki,
  company_name: "GlobalLogic",
  event_name: "Tech Internship",
  duration: :long_term,
  content: "3ヶ月の長期インターン。実際のプロダクト開発に参加。英語でのコミュニケーションが最初大変だったけど慣れると楽しい。",
  days_ago: 120)

create_intern_post(yuki,
  company_name: "ByteLink",
  event_name: "1day Workshop",
  duration: :short_term,
  content: "1dayだけど密度濃かった。APIの設計について学べた。",
  days_ago: 200)

create_intern_post(yuki,
  company_name: "CodeWave",
  event_name: "Winter Internship",
  duration: :medium_term,
  content: "1週間のハッカソン形式。チーム開発でGit運用の重要性を学んだ。",
  days_ago: 90)

create_intern_post(yuki,
  company_name: "SeedSpark",
  event_name: "Startup Experience",
  duration: :short_term,
  content: "3日間のベンチャー体験。スピード感がすごい。意思決定の速さに驚いた。",
  days_ago: 150)

# つぶやき
create_general_post(yuki, "今週だけで面接5社。移動が大変だけど充実してる #就活", days_ago: 4)
create_general_post(yuki, "外資の最終面接、英語でケース面接だった。なんとか乗り切った感。", days_ago: 2)

# ===========================================
# demo（あなた）の投稿 - 選考過程を記録
# ===========================================
puts "  demoの投稿を作成中..."

# TechNova: ES→1次 進行中
create_job_hunting_post(demo,
  company_name: "TechNova",
  stage: :es,
  result: :passed,
  content: "書類通過！インターンで行った会社だから志望動機書きやすかった。",
  days_ago: 10)

create_job_hunting_post(demo,
  company_name: "TechNova",
  stage: :first_interview,
  result: :pending,
  content: "1次面接終わった。技術質問は答えられたけど、逆質問がイマイチだったかも...",
  days_ago: 3)

# CodeWave: ES→1次 進行中
create_job_hunting_post(demo,
  company_name: "CodeWave",
  stage: :es,
  result: :passed,
  content: "Web系ベンチャー。プロダクトへの共感を軸に書いた。",
  days_ago: 8)

create_job_hunting_post(demo,
  company_name: "CodeWave",
  stage: :first_interview,
  result: :pending,
  content: "1次面接終わった。緊張したけど、自分の言葉で話せた気がする。結果待ち...",
  days_ago: 2)

# BlueSystems: ES落ち
create_job_hunting_post(demo,
  company_name: "BlueSystems",
  stage: :es,
  result: :failed,
  content: "SIer初応募。ES落ち。志望動機が弱かったかも。次に活かす。",
  days_ago: 12)

# インターン記録（2社分）
create_intern_post(demo,
  company_name: "TechNova",
  event_name: "Summer Internship 2025",
  duration: :medium_term,
  content: "2週間のインターン。Railsでの開発を経験。メンターさんが丁寧で成長できた。",
  days_ago: 180)

create_intern_post(demo,
  company_name: "LaunchPad",
  event_name: "1day Hackathon",
  duration: :short_term,
  content: "1dayハッカソン。チームで簡単なWebアプリ作った。楽しかった！",
  days_ago: 150)

# つぶやき
create_general_post(demo, "今日はES3社出した、偉い #就活", days_ago: 5)
create_general_post(demo, "ポートフォリオ更新した！Railsで就活管理アプリ作ってる #Rails #ポートフォリオ", days_ago: 4)
create_general_post(demo, "面接対策で想定質問100個洗い出した。準備大事。 #就活", days_ago: 1)

# ===========================================
# riku（普通の就活生）の投稿
# ===========================================
puts "  riku_25の投稿を作成中..."

# ByteLink: ES→1次落ち
create_job_hunting_post(riku,
  company_name: "ByteLink",
  stage: :es,
  result: :passed,
  content: "初めてES通った！嬉しい。面接準備しなきゃ。",
  days_ago: 10)

create_job_hunting_post(riku,
  company_name: "ByteLink",
  stage: :first_interview,
  result: :failed,
  content: "1次落ち。「なぜIT業界？」の深掘りでうまく答えられなかった。もっと自己分析必要。",
  days_ago: 5)

# DataBridge: ES通過
create_job_hunting_post(riku,
  company_name: "DataBridge",
  stage: :es,
  result: :passed,
  content: "SIer応募。安定志向の理由を正直に書いた。",
  days_ago: 7)

create_job_hunting_post(riku,
  company_name: "DataBridge",
  stage: :first_interview,
  result: :pending,
  content: "1次面接終わった。緊張で早口になっちゃった...結果待ち。",
  days_ago: 2)

# SeedSpark: ES待ち
create_job_hunting_post(riku,
  company_name: "SeedSpark",
  stage: :es,
  result: :pending,
  content: "ベンチャー初応募。成長環境を求めてる理由をしっかり書いた。",
  days_ago: 6)

# インターン記録（1社）
create_intern_post(riku,
  company_name: "DataBridge",
  event_name: "1day 仕事体験",
  duration: :short_term,
  content: "1dayの仕事体験。SIerの仕事内容がイメージできた。",
  days_ago: 160)

# つぶやき
create_general_post(riku, "ES書くの苦手すぎる...ガクチカが薄い #就活 #ES", days_ago: 8)
create_general_post(riku, "やっとES1社出せた。小さな一歩。 #就活", days_ago: 6)
create_general_post(riku, "面接で頭真っ白になった。練習不足だ... #就活", days_ago: 3)

# ===========================================
# miku（不安な就活生）の投稿
# ===========================================
puts "  miku_anxの投稿を作成中..."

# LaunchPad: ES落ち
create_job_hunting_post(miku,
  company_name: "LaunchPad",
  stage: :es,
  result: :failed,
  content: "また落ちた。何がダメなのかわからない...",
  days_ago: 7)

# CodeWave: ES待ち
create_job_hunting_post(miku,
  company_name: "CodeWave",
  stage: :es,
  result: :pending,
  content: "先輩にES見てもらって書き直した。今度こそ通りますように。",
  days_ago: 1)

# TechNova: ES落ち
create_job_hunting_post(miku,
  company_name: "TechNova",
  stage: :es,
  result: :failed,
  content: "TechNovaもダメだった...志望動機が弱いのかな。",
  days_ago: 14)

# つぶやき
create_general_post(miku, "周りがどんどん内定取ってて焦る...私だけ取り残されてる気がする #就活 #不安", days_ago: 5)
create_general_post(miku, "ESの書き方がわからない。誰かアドバイスください... #就活 #ESレビュー", days_ago: 3)
create_general_post(miku, "今日は説明会2社参加した。少しずつ前に進んでる...と思いたい。 #就活", days_ago: 1)

# ===========================================
# senpai（内定済み先輩）の投稿
# ===========================================
puts "  senpai_naiteiの投稿を作成中..."

# インターン記録（3社分）
create_intern_post(senpai,
  company_name: "GlobalLogic",
  event_name: "Summer Internship",
  duration: :long_term,
  content: "3ヶ月のインターン。実際のプロダクト開発に参加できた。英語でのコミュニケーションが最初大変だったけど、慣れると楽しい。ここでの経験が内定に繋がった。",
  days_ago: 400)

create_intern_post(senpai,
  company_name: "TechNova",
  event_name: "Winter Internship",
  duration: :medium_term,
  content: "2週間でチーム開発。アジャイル開発を実践で学べた。",
  days_ago: 350)

create_intern_post(senpai,
  company_name: "ByteLink",
  event_name: "1day Workshop",
  duration: :short_term,
  content: "1dayで技術課題を解く形式。短いけど会社の雰囲気がわかった。",
  days_ago: 380)

# つぶやき
create_general_post(senpai, "後輩の就活相談乗ってる。去年の自分を思い出す。みんな頑張れ！ #就活", days_ago: 10)
create_general_post(senpai, "ESレビュー依頼来たら基本見るので気軽にDMください！ #ESレビュー", days_ago: 5)
create_general_post(senpai, "就活は情報戦。Commitlyで情報共有していこう #就活 #Commitly", days_ago: 2)

puts "=== デモ用投稿作成完了 ==="