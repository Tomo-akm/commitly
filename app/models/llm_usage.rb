class LlmUsage < ApplicationRecord
  belongs_to :user

  validates :usage_date, presence: true
  validates :count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :usage_date, uniqueness: { scope: :user_id }

  DAILY_LIMIT = 20

  class LimitExceededError < StandardError; end

  def self.find_or_create_today(user)
    find_or_create_by(user: user, usage_date: Date.current) do |usage|
      usage.count = 0
    end
  end

  def increment_count!
    with_lock do
      increment!(:count)
    end
  end

  # 制限チェックと使用回数予約（原子的に実行）
  def self.check_and_reserve!(user)
    return if user.admin?

    usage = find_or_create_today(user)
    usage.with_lock do
      raise LimitExceededError if usage.count >= DAILY_LIMIT
      usage.increment!(:count)
    end
  end

  # 残り回数
  def self.remaining_count(user)
    return Float::INFINITY if user.admin?

    current = find_or_create_today(user).count
    [ DAILY_LIMIT - current, 0 ].max
  end

  # 使用統計
  def self.stats(user)
    {
      is_admin: user.admin?,
      daily_limit: user.admin? ? nil : DAILY_LIMIT,
      today_count: user.admin? ? nil : find_or_create_today(user).count,
      remaining: remaining_count(user)
    }
  end
end
