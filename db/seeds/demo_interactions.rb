# frozen_string_literal: true

# デモ用インタラクション（ES共有投稿・リプライ・いいね）の作成
puts "=== デモ用インタラクションを作成中 ==="

demo = User.find_by(account_id: "demo")
yuki = User.find_by(account_id: "yuki_dev")
riku = User.find_by(account_id: "riku_26")
miku = User.find_by(account_id: "miku_anx")
senpai = User.find_by(account_id: "senpai_naitei")

# URL生成用ヘルパー（環境に応じたホストを使用）
def vault_entry_sheet_url(entry_sheet)
  Rails.application.routes.url_helpers.vault_entry_sheet_url(
    entry_sheet,
    **Rails.application.config.action_mailer.default_url_options
  )
end

# リプライ作成用ヘルパー
def create_reply(user, parent_post, content, days_ago: 0)
  return if user.nil? || parent_post.nil?

  general = GeneralContent.create!(content: content)
  Post.create!(
    user: user,
    contentable: general,
    parent: parent_post,
    created_at: days_ago.days.ago,
    updated_at: days_ago.days.ago
  )
end

# つぶやき投稿作成用ヘルパー
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

# ===========================================
# ES共有投稿 + 先輩FBリプライ
# ===========================================
puts "  ES共有投稿とFBリプライを作成中..."

# demo の ES共有投稿
demo_es = EntrySheet.find_by(user: demo, company_name: "TechNova")
if demo && demo_es
  es_share_post = create_general_post(
    demo,
    "TechNovaのES公開しました！志望動機のところ、もっと具体的にした方がいいかアドバイスください\n\n#{vault_entry_sheet_url(demo_es)}\n\n#就活 #ESレビュー",
    days_ago: 1
  )

  # senpai からのFBリプライ
  if senpai && es_share_post
    fb_reply = create_reply(
      senpai,
      es_share_post,
      "ES見ました！全体的に良いと思います。\n\n改善点を1つだけ挙げるとすると、「技術で社会を良くする」の部分をもう少し具体的にするといいかも。例えば「御社の○○サービスで△△の課題を解決したい」のように、具体的なサービス名と課題を入れると説得力が増します。\n\n頑張ってください！",
      days_ago: 0
    )

    # demo からのお礼リプライ
    if fb_reply
      create_reply(
        demo,
        fb_reply,
        "ありがとうございます！確かに抽象的でした。TechNovaの具体的なサービスを調べて書き直してみます！",
        days_ago: 0
      )
    end
  end

  # yuki からもリプライ
  if yuki && es_share_post
    create_reply(
      yuki,
      es_share_post,
      "インターンの経験を志望動機に入れてるの良いね！自分も同じ戦略で書いてた。「成長できた」だけじゃなく、「具体的に何ができるようになったか」を入れるとさらに強くなると思う！",
      days_ago: 0
    )
  end
end

# miku の ES共有投稿（改善前のES）
miku_es = EntrySheet.find_by(user: miku, company_name: "CodeWave")
if miku && miku_es
  miku_share_post = create_general_post(
    miku,
    "ESの書き方がわからなくて...CodeWaveのES、誰か見てもらえませんか？\n\n#{vault_entry_sheet_url(miku_es)}\n\n#就活 #ESレビュー #助けて",
    days_ago: 2
  )

  # senpai からの丁寧なFBリプライ
  if senpai && miku_share_post
    fb_reply = create_reply(
      senpai,
      miku_share_post,
      "ES見ました！最初は誰でもこんな感じだから大丈夫。\n\nいくつかアドバイスするね：\n\n1. 「興味がある」だけだと弱いので、「なぜ興味を持ったか」のきっかけを書こう\n2. 「使いやすい」と思った理由を具体的に\n3. 「頑張りたい」より「○○を実現したい」の方が伝わる\n\nDMで詳しく相談乗るよ！",
      days_ago: 1
    )

    # miku からのお礼
    if fb_reply
      create_reply(
        miku,
        fb_reply,
        "ありがとうございます！！具体的に何を書けばいいかわかりました。DM送らせてください！",
        days_ago: 1
      )
    end
  end

  # riku からの共感リプライ
  if riku && miku_share_post
    create_reply(
      riku,
      miku_share_post,
      "自分も最初そんな感じだった...一緒に頑張ろう！",
      days_ago: 1
    )
  end
end

# riku の ES共有投稿
riku_es = EntrySheet.find_by(user: riku, company_name: "DataBridge")
if riku && riku_es
  riku_share_post = create_general_post(
    riku,
    "SIer向けのES、これでいいのかな...添削お願いします\n\n#{vault_entry_sheet_url(riku_es)}\n\n#就活 #ESレビュー #SIer",
    days_ago: 2
  )

  # senpai からのFBリプライ
  if senpai && riku_share_post
    create_reply(
      senpai,
      riku_share_post,
      "SIerのES、悪くないと思う！\n\n「安定性と信頼性が求められる開発に挑戦」の部分、もう少し具体的に「なぜ自分がそこにやりがいを感じるか」を書くと良いかも。\n\nあと、研修制度への期待だけだと受け身に見えるから、「研修で○○を学び、△△に活かしたい」のように主体性を見せるといいよ！",
      days_ago: 1
    )
  end
end

# yuki の通過ES共有投稿（お手本として）
yuki_es = EntrySheet.find_by(user: yuki, company_name: "GlobalLogic")
if yuki && yuki_es
  yuki_share_post = create_general_post(
    yuki,
    "GlobalLogicのES通過しました！！参考になれば公開しておきます\n\n#{vault_entry_sheet_url(yuki_es)}\n\n#就活 #ES #外資IT #内定",
    days_ago: 1
  )

  # demo からのリプライ
  if demo && yuki_share_post
    create_reply(
      demo,
      yuki_share_post,
      "おめでとう！！ES参考になります。インターン経験を具体的に書いてるの、すごく説得力ある。",
      days_ago: 0
    )
  end

  # miku からのリプライ
  if miku && yuki_share_post
    create_reply(
      miku,
      yuki_share_post,
      "すごい...！参考にさせてもらいます！",
      days_ago: 0
    )
  end
end

# ===========================================
# その他のリプライ（SNS感を出す）
# ===========================================
puts "  その他のリプライを作成中..."

# demo の面接投稿へのリプライ
demo_interview_post = Post.joins("INNER JOIN job_hunting_contents ON job_hunting_contents.id = posts.contentable_id")
                          .where(user: demo, contentable_type: "JobHuntingContent")
                          .where("job_hunting_contents.company_name = ?", "CodeWave")
                          .order(created_at: :desc)
                          .first

if demo_interview_post && riku
  create_reply(
    riku,
    demo_interview_post,
    "CodeWave自分も受けてる！面接どんな感じだった？",
    days_ago: 1
  )
end

# miku の不安投稿へのリプライ
miku_anxiety_post = Post.joins("INNER JOIN general_contents ON general_contents.id = posts.contentable_id")
                        .where(user: miku, contentable_type: "GeneralContent")
                        .where("general_contents.content LIKE ?", "%焦る%")
                        .first

if miku_anxiety_post && senpai
  create_reply(
    senpai,
    miku_anxiety_post,
    "去年の自分も同じ気持ちだったよ。周りと比べても意味ないから、自分のペースで大丈夫。応援してる！",
    days_ago: 4
  )
end

if miku_anxiety_post && demo
  create_reply(
    demo,
    miku_anxiety_post,
    "わかる...自分も焦ってる。一緒に頑張ろう！",
    days_ago: 4
  )
end

# ===========================================
# いいね
# ===========================================
puts "  いいねを作成中..."

# yuki の内定投稿にみんながいいね
yuki_naitei_post = Post.joins("INNER JOIN job_hunting_contents ON job_hunting_contents.id = posts.contentable_id")
                       .where(user: yuki, contentable_type: "JobHuntingContent")
                       .where("job_hunting_contents.result = ?", JobHuntingContent.results[:passed])
                       .where("job_hunting_contents.selection_stage = ?", JobHuntingContent.selection_stages[:final_interview])
                       .first

[demo, riku, miku, senpai].each do |user|
  next if user.nil? || yuki_naitei_post.nil?
  Like.find_or_create_by!(user: user, post: yuki_naitei_post)
end

# senpai の応援投稿にいいね
senpai_cheer_post = Post.joins("INNER JOIN general_contents ON general_contents.id = posts.contentable_id")
                        .where(user: senpai, contentable_type: "GeneralContent")
                        .where("general_contents.content LIKE ?", "%ESレビュー依頼%")
                        .first

[demo, riku, miku, yuki].each do |user|
  next if user.nil? || senpai_cheer_post.nil?
  Like.find_or_create_by!(user: user, post: senpai_cheer_post)
end

# ES共有投稿にいいね
[demo, yuki, riku, miku].each do |user|
  next if user.nil?

  # 各ユーザーのES共有投稿を取得していいね
  es_posts = Post.joins("INNER JOIN general_contents ON general_contents.id = posts.contentable_id")
                 .where(contentable_type: "GeneralContent")
                 .where("general_contents.content LIKE ?", "%#ESレビュー%")
                 .where.not(user: user)

  es_posts.each do |post|
    Like.find_or_create_by!(user: user, post: post)
  end
end

# 各ユーザーの投稿にランダムにいいね（SNS感を出す）
all_users = [demo, yuki, riku, miku, senpai].compact
Post.where(parent_id: nil).find_each do |post|
  # 投稿者以外からランダムに1〜3人がいいね
  likers = all_users.reject { |u| u == post.user }.sample(rand(1..3))
  likers.each do |liker|
    Like.find_or_create_by!(user: liker, post: post)
  end
end

puts "=== デモ用インタラクション作成完了 ==="