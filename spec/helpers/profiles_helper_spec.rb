# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfilesHelper, type: :helper do
  let(:user) { create(:user) }

  describe "#commit_log_tab_path" do
    context "params[:account_id]が存在する場合" do
      before { params[:account_id] = user.account_id }

      it "user_profile_pathを返す" do
        expect(helper.commit_log_tab_path).to eq(user_profile_path(user.account_id))
      end
    end

    context "params[:account_id]が存在しない場合" do
      before { allow(helper).to receive(:current_user).and_return(user) }

      it "current_userのuser_profile_pathを返す" do
        expect(helper.commit_log_tab_path).to eq(user_profile_path(user.account_id))
      end
    end
  end

  describe "#commit_log_tab_active?" do
    before do
      params[:account_id] = user.account_id
    end

    it "commit logページで表示される場合、trueを返す" do
      allow(helper).to receive(:current_page?).with(user_profile_path(user.account_id)).and_return(true)
      expect(helper.commit_log_tab_active?).to be true
    end

    it "commit logページでない場合、falseを返す" do
      allow(helper).to receive(:current_page?).with(user_profile_path(user.account_id)).and_return(false)
      expect(helper.commit_log_tab_active?).to be false
    end
  end

  describe "#stars_tab_path" do
    before { allow(helper).to receive(:current_user).and_return(user) }

    it "user_profile_likes_pathを返す" do
      expect(helper.stars_tab_path).to eq(user_profile_likes_path(user.account_id))
    end
  end

  describe "#stars_tab_active?" do
    before do
      params[:account_id] = user.account_id
      allow(helper).to receive(:current_user).and_return(user)
    end

    it "Starsページで表示される場合、trueを返す" do
      allow(helper).to receive(:current_page?).with(user_profile_likes_path(user.account_id)).and_return(true)
      expect(helper.stars_tab_active?).to be true
    end

    it "Starsページでない場合、falseを返す" do
      allow(helper).to receive(:current_page?).with(user_profile_likes_path(user.account_id)).and_return(false)
      expect(helper.stars_tab_active?).to be false
    end
  end
end
