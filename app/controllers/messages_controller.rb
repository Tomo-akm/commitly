class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_room

  def create
    @message = @room.messages.build(message_params)
    @message.user = current_user

    if @message.save
      mark_room_as_read
      @messages = @room.messages.includes(:user).order(created_at: :asc)
      @message = Message.new
      set_rooms_for_full_page

      respond_to do |format|
        format.turbo_stream
        format.html { render "rooms/show" }
      end
    else
      @messages = @room.messages.includes(:user).order(created_at: :asc)
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

  def message_params
    params.expect(message: [ :content ])
  end

  def set_rooms_for_full_page
    @rooms = current_user.rooms
                         .includes(:users, messages: :user)
                         .left_joins(:messages)
                         .group("rooms.id")
                         .order("MAX(messages.created_at) DESC NULLS LAST")
  end
end
