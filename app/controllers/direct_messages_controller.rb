class DirectMessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_room

  def create
    @direct_message = @room.direct_messages.build(direct_message_params)
    @direct_message.user = current_user

    if @direct_message.save
      mark_room_as_read
      @direct_messages = @room.direct_messages.includes(:user).order(created_at: :asc)
      @direct_message = DirectMessage.new
      set_rooms_for_full_page

      respond_to do |format|
        format.turbo_stream
        format.html { render "rooms/show" }
      end
    else
      @direct_messages = @room.direct_messages.includes(:user).order(created_at: :asc)
      set_rooms_for_full_page
      flash.now[:alert] = "メッセージの送信に失敗しました"
      render "rooms/show", status: :unprocessable_entity
    end
  end

  private

  def set_room
    other_user = User.find(params[:room_id])
    @room = Room.between(current_user, other_user)
  end

  def mark_room_as_read
    entry = current_user.entries.find_by(room: @room)
    entry&.mark_as_read!
  end

  def direct_message_params
    params.expect(direct_message: [ :content ])
  end

  def set_rooms_for_full_page
    @rooms = current_user.rooms
                         .includes(:users, direct_messages: :user)
                         .left_joins(:direct_messages)
                         .group("rooms.id")
                         .order("MAX(direct_messages.created_at) DESC NULLS LAST")
  end
end
