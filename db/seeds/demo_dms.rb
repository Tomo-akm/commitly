# frozen_string_literal: true

# デモ用DM（ダイレクトメッセージ）の作成
puts "=== デモ用DMを作成中 ==="

demo = User.find_by(account_id: "demo")
yuki = User.find_by(account_id: "yuki_dev")
riku = User.find_by(account_id: "riku_26")
miku = User.find_by(account_id: "miku_anx")
senpai = User.find_by(account_id: "senpai_naitei")

# DM作成用ヘルパー（after_create_commit のブロードキャストをスキップ）
def create_dm_without_broadcast(room, user, content, hours_ago: 0)
  return if room.nil? || user.nil?

  DirectMessage.insert!({
    room_id: room.id,
    user_id: user.id,
    content: content,
    created_at: hours_ago.hours.ago,
    updated_at: hours_ago.hours.ago
  })
end

# ===========================================
# demo と senpai のDM（ES添削相談）
# ===========================================
if demo && senpai
  puts "  demo - senpai のDMを作成中..."

  room = Room.between(demo, senpai)

  create_dm_without_broadcast(room, demo, "先輩、お忙しいところすみません！TechNovaのES、もう少し詳しく見ていただけませんか？", hours_ago: 24)
  create_dm_without_broadcast(room, senpai, "もちろん！さっき投稿にもコメントしたけど、もう少し詳しく話そうか", hours_ago: 23)
  create_dm_without_broadcast(room, demo, "ありがとうございます！「技術で社会を良くする」の部分、具体的にどう書けばいいですか？", hours_ago: 22)
  create_dm_without_broadcast(room, senpai, "TechNovaのサービスを調べて、自分が共感したポイントを書くといいよ。例えば「御社の○○サービスは、△△という課題を解決しており、私も□□の経験から同じ課題意識を持っています」みたいな感じ", hours_ago: 21)
  create_dm_without_broadcast(room, senpai, "あと、インターンで感じたことをもっと具体的に書くのもアリ。「2週間のインターンで○○を経験し、××の重要性を学びました」とか", hours_ago: 21)
  create_dm_without_broadcast(room, demo, "なるほど！具体的なサービス名を入れるんですね。調べてみます！", hours_ago: 20)
  create_dm_without_broadcast(room, demo, "書き直したらまた見てもらっていいですか？", hours_ago: 20)
  create_dm_without_broadcast(room, senpai, "もちろん！いつでも送って", hours_ago: 19)

  # 既読状態を設定（senpai は最後まで読んだ、demo は未読あり）
  room.entries.find_by(user: senpai)&.update!(last_read_at: 19.hours.ago)
  room.entries.find_by(user: demo)&.update!(last_read_at: 20.hours.ago)
end

# ===========================================
# miku と senpai のDM（ES相談）
# ===========================================
if miku && senpai
  puts "  miku - senpai のDMを作成中..."

  room = Room.between(miku, senpai)

  create_dm_without_broadcast(room, miku, "先輩、ESの相談乗ってもらえますか...？", hours_ago: 48)
  create_dm_without_broadcast(room, senpai, "もちろん！どうしたの？", hours_ago: 47)
  create_dm_without_broadcast(room, miku, "何社かES出してるんですけど、全然通らなくて...何がダメなのかわからないんです", hours_ago: 46)
  create_dm_without_broadcast(room, senpai, "ES見せてもらっていい？Vaultで公開してくれたら見るよ", hours_ago: 45)
  create_dm_without_broadcast(room, miku, "公開しました！CodeWaveのやつです", hours_ago: 44)
  create_dm_without_broadcast(room, senpai, "見たよ！いくつかアドバイスあるから投稿にコメントしたね。\n\n一番大事なのは「なぜその会社なのか」を具体的に書くこと。「興味がある」だけだと、どの会社にも言える内容になっちゃうから", hours_ago: 43)
  create_dm_without_broadcast(room, senpai, "あと、「頑張りたい」より「○○を実現したい」の方が伝わるよ。目標を具体的に書こう", hours_ago: 43)
  create_dm_without_broadcast(room, miku, "ありがとうございます！！確かに、どの会社にも出せる内容になってました...", hours_ago: 42)
  create_dm_without_broadcast(room, miku, "CodeWaveのサービスをもっと調べて、書き直してみます！", hours_ago: 42)
  create_dm_without_broadcast(room, senpai, "いいね！焦らなくて大丈夫だから、一社一社丁寧に書いていこう", hours_ago: 41)

  # 既読状態を設定
  room.entries.find_by(user: senpai)&.update!(last_read_at: 41.hours.ago)
  room.entries.find_by(user: miku)&.update!(last_read_at: 41.hours.ago)
end

# ===========================================
# demo と riku のDM（面接情報共有）
# ===========================================
if demo && riku
  puts "  demo - riku のDMを作成中..."

  room = Room.between(demo, riku)

  create_dm_without_broadcast(room, riku, "CodeWave受けてるって見たんだけど、面接どんな感じだった？", hours_ago: 12)
  create_dm_without_broadcast(room, demo, "1次面接は技術質問が中心だったよ。使ってる技術スタックとか、個人開発の話とか", hours_ago: 11)
  create_dm_without_broadcast(room, riku, "ありがとう！技術質問かー、準備しなきゃ", hours_ago: 10)
  create_dm_without_broadcast(room, demo, "あと「チームで開発した経験」も聞かれたから、エピソード準備しておくといいかも", hours_ago: 10)
  create_dm_without_broadcast(room, riku, "了解！助かる！お互い頑張ろう", hours_ago: 9)

  # 既読状態を設定（demo に未読あり）
  room.entries.find_by(user: riku)&.update!(last_read_at: 9.hours.ago)
  room.entries.find_by(user: demo)&.update!(last_read_at: 11.hours.ago)
end

puts "=== デモ用DM作成完了 ==="