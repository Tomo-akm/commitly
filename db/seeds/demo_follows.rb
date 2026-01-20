# frozen_string_literal: true

# デモ用フォロー関係の作成
puts "=== デモ用フォロー関係を作成中 ==="

demo = User.find_by(account_id: "demo")
yuki = User.find_by(account_id: "yuki_dev")
riku = User.find_by(account_id: "riku_26")
miku = User.find_by(account_id: "miku_anx")
senpai = User.find_by(account_id: "senpai_naitei")

# フォロー関係の定義
# [フォローする人, フォローされる人]
FOLLOW_PAIRS = [
  # demo（あなた）の相互フォロー
  [demo, riku],
  [riku, demo],
  [demo, miku],
  [miku, demo],
  [demo, senpai],
  [senpai, demo],
  [demo, yuki],

  # yuki（強者）はみんなにフォローされてる
  [riku, yuki],
  [miku, yuki],
  [senpai, yuki],

  # senpai（先輩）はみんなにフォローされてる
  [riku, senpai],
  [miku, senpai],
  [yuki, senpai],

  # その他の繋がり
  [riku, miku],
  [miku, riku]
].freeze

FOLLOW_PAIRS.each do |follower, followed|
  next if follower.nil? || followed.nil?

  unless Follow.exists?(follower: follower, followed: followed)
    Follow.create!(follower: follower, followed: followed)
    puts "  #{follower.account_id} → #{followed.account_id}"
  end
end

puts "=== デモ用フォロー関係作成完了 ==="