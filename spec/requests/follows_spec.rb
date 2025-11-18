require 'rails_helper'

RSpec.describe "Follows", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in user
  end

  describe "POST /users/:user_id/follows" do
    it "creates a new follow" do
      expect {
        post user_follows_path(other_user)
      }.to change(Follow, :count).by(1)
    end

    it "does not allow a user to follow themselves" do
      expect {
        post user_follows_path(user)
      }.to_not change(Follow, :count)
    end
  end

  describe "DELETE /users/:user_id/follows/:id" do
    let!(:follow) { create(:follow, follower: user, followed: other_user) }

    it "destroys the follow" do
      expect {
        delete user_follow_path(other_user, follow)
      }.to change(Follow, :count).by(-1)
    end
  end
end
