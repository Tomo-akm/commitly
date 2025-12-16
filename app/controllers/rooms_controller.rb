class RoomsController < ApplicationController
  before_action :authenticate_user!

  def index
    @rooms = current_user.rooms
                         .includes(:users, direct_messages: :user)
                         .left_joins(:direct_messages)
                         .group("rooms.id")
                         .order("MAX(direct_messages.created_at) DESC NULLS LAST")
  end

  def show
    other_user = User.find(params[:id])
    @room = Room.between(current_user, other_user)

    mark_room_as_read

    @direct_messages = @room.direct_messages.includes(:user).order(created_at: :asc)
    @direct_message = DirectMessage.new

    # 通常のリクエスト（turbo_frameでない）場合はDM一覧も取得
    unless turbo_frame_request?
      @rooms = current_user.rooms
                           .includes(:users, direct_messages: :user)
                           .left_joins(:direct_messages)
                           .group("rooms.id")
                           .order("MAX(direct_messages.created_at) DESC NULLS LAST")
    end
  end

  def create
    other_user = User.find(params[:user_id])
    @room = Room.between(current_user, other_user)
    redirect_to room_path(other_user)
  end

  def mark_as_read
    other_user = User.find(params[:id])
    @room = Room.between(current_user, other_user)
    mark_room_as_read
    head :ok
  end

  private

  def mark_room_as_read
    entry = current_user.entries.find_by(room: @room)
    entry&.mark_as_read!
  end
end
