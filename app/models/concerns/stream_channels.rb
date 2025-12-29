# Turbo Streamsのチャネル名を一元管理するConcern
#
# リアルタイム通知やDMのブロードキャスト先チャネル名を定数化し、
# マジックストリングの散在を防ぎます。
#
# @example Userモデルでの使用
#   class User < ApplicationRecord
#     include StreamChannels
#   end
#
#   # インスタンスメソッド（推奨）
#   user.notification_channel
#   # => "user_123_notifications"
#
#   user.room_detail_channel(room_id)
#   # => "room_456_user_123"
#
#   # クラスメソッド（IDを直接指定する場合）
#   User.notification_channel(user_id)
#   # => "user_123_notifications"
#
# @example ビューでの使用
#   = turbo_stream_from current_user.notification_channel
#   = turbo_stream_from current_user.room_detail_channel(@room.id)
#
module StreamChannels
  extend ActiveSupport::Concern

  class_methods do
    # ユーザー単位の通知チャネル名を生成
    #
    # 全画面で共通の通知（未読バッジ、DM一覧更新など）を
    # ブロードキャストする際に使用します。
    #
    # @param user_id [Integer] ユーザーID
    # @return [String] チャネル名（例: "user_123_notifications"）
    def notification_channel(user_id)
      "user_#{user_id}_notifications"
    end

    # ルーム×ユーザー単位の詳細チャネル名を生成
    #
    # 特定のDMルームを開いているユーザーに対して
    # メッセージをブロードキャストする際に使用します。
    #
    # @param room_id [Integer] ルームID
    # @param user_id [Integer] ユーザーID
    # @return [String] チャネル名（例: "room_456_user_123"）
    def room_detail_channel(room_id, user_id)
      "room_#{room_id}_user_#{user_id}"
    end
  end

  # 自分の通知チャネル名を取得（インスタンスメソッド）
  #
  # @return [String] チャネル名
  def notification_channel
    self.class.notification_channel(id)
  end

  # 自分が参加するルームの詳細チャネル名を取得（インスタンスメソッド）
  #
  # @param room_id [Integer] ルームID
  # @return [String] チャネル名
  def room_detail_channel(room_id)
    self.class.room_detail_channel(room_id, id)
  end
end
