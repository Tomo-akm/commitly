# frozen_string_literal: true

# デモ用バッジ（実績）の付与
puts "=== デモ用バッジを付与中 ==="

demo = User.find_by(account_id: "demo")
yuki = User.find_by(account_id: "yuki_dev")
riku = User.find_by(account_id: "riku_26")
miku = User.find_by(account_id: "miku_anx")
senpai = User.find_by(account_id: "senpai_naitei")

# バッジ付与用ヘルパー
def grant_achievement(user, achievement_key, days_ago: 0)
  return if user.nil?

  UserAchievement.find_or_create_by!(user: user, achievement_key: achievement_key.to_s) do |ua|
    ua.achieved_at = days_ago.days.ago
  end
end

# ===========================================
# demo のバッジ
# ===========================================
if demo
  puts "  demoのバッジを付与中..."
  grant_achievement(demo, :first_post, days_ago: 30)           # ファーストコミット
  grant_achievement(demo, :first_follow, days_ago: 28)         # リンクスタート
  grant_achievement(demo, :first_es_public, days_ago: 1)       # ESオープン
  grant_achievement(demo, :first_review_request, days_ago: 1)  # レビューコール
  grant_achievement(demo, :streak_7, days_ago: 7)              # 連続7日
  grant_achievement(demo, :company_progress_3, days_ago: 5)    # 企業3社
end

# ===========================================
# yuki のバッジ（強者なので多め）
# ===========================================
if yuki
  puts "  yuki_devのバッジを付与中..."
  grant_achievement(yuki, :first_post, days_ago: 180)
  grant_achievement(yuki, :first_follow, days_ago: 180)
  grant_achievement(yuki, :first_es_public, days_ago: 90)
  grant_achievement(yuki, :first_review_request, days_ago: 60)
  grant_achievement(yuki, :streak_7, days_ago: 60)
  grant_achievement(yuki, :streak_14, days_ago: 30)
  grant_achievement(yuki, :streak_30, days_ago: 7)             # 連続30日達成
  grant_achievement(yuki, :weekly_goal_1, days_ago: 50)
  grant_achievement(yuki, :weekly_goal_2, days_ago: 30)
  grant_achievement(yuki, :weekly_goal_3, days_ago: 14)        # 週間スプリント3週
  grant_achievement(yuki, :monthly_goal_1, days_ago: 60)
  grant_achievement(yuki, :monthly_goal_2, days_ago: 30)       # 月間マイルストーン2ヶ月
  grant_achievement(yuki, :es_public_3, days_ago: 30)          # ES公開3件
  grant_achievement(yuki, :mutual_follow_5, days_ago: 90)      # 相互フォロー5人
  grant_achievement(yuki, :company_progress_3, days_ago: 60)
  grant_achievement(yuki, :company_progress_5, days_ago: 30)   # 企業5社
end

# ===========================================
# riku のバッジ
# ===========================================
if riku
  puts "  riku_25のバッジを付与中..."
  grant_achievement(riku, :first_post, days_ago: 20)
  grant_achievement(riku, :first_follow, days_ago: 18)
  grant_achievement(riku, :first_es_public, days_ago: 2)
  grant_achievement(riku, :first_review_request, days_ago: 2)
  grant_achievement(riku, :company_progress_3, days_ago: 5)
end

# ===========================================
# miku のバッジ（少なめ）
# ===========================================
if miku
  puts "  miku_anxのバッジを付与中..."
  grant_achievement(miku, :first_post, days_ago: 14)
  grant_achievement(miku, :first_follow, days_ago: 12)
  grant_achievement(miku, :first_es_public, days_ago: 1)
  grant_achievement(miku, :first_review_request, days_ago: 2)
end

# ===========================================
# senpai のバッジ（内定者なので多め）
# ===========================================
if senpai
  puts "  senpai_naiteiのバッジを付与中..."
  grant_achievement(senpai, :first_post, days_ago: 365)
  grant_achievement(senpai, :first_follow, days_ago: 365)
  grant_achievement(senpai, :first_es_public, days_ago: 300)
  grant_achievement(senpai, :first_review_request, days_ago: 280)
  grant_achievement(senpai, :streak_7, days_ago: 300)
  grant_achievement(senpai, :streak_14, days_ago: 270)
  grant_achievement(senpai, :streak_30, days_ago: 240)
  grant_achievement(senpai, :weekly_goal_1, days_ago: 320)
  grant_achievement(senpai, :weekly_goal_2, days_ago: 280)
  grant_achievement(senpai, :weekly_goal_3, days_ago: 250)
  grant_achievement(senpai, :monthly_goal_1, days_ago: 300)
  grant_achievement(senpai, :monthly_goal_2, days_ago: 270)
  grant_achievement(senpai, :monthly_goal_3, days_ago: 240)    # 月間マイルストーン3ヶ月
  grant_achievement(senpai, :es_public_3, days_ago: 280)
  grant_achievement(senpai, :es_public_5, days_ago: 250)       # ES公開5件
  grant_achievement(senpai, :review_request_3, days_ago: 260)
  grant_achievement(senpai, :review_request_5, days_ago: 230)  # レビューコール5回
  grant_achievement(senpai, :mutual_follow_5, days_ago: 300)
  grant_achievement(senpai, :mutual_follow_10, days_ago: 250)  # 相互フォロー10人
  grant_achievement(senpai, :template_3, days_ago: 200)        # テンプレート3件
  grant_achievement(senpai, :company_progress_3, days_ago: 300)
  grant_achievement(senpai, :company_progress_5, days_ago: 270)
  grant_achievement(senpai, :company_progress_7, days_ago: 240) # 企業7社
end

puts "=== デモ用バッジ付与完了 ==="