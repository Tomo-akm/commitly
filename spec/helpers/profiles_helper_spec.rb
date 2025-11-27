# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfilesHelper, type: :helper do
  let(:user) { create(:user) }

  describe "#commit_log_tab_path" do
    context "params[:id]が存在する場合" do
      before { params[:id] = user.id.to_s }

      it "user_profile_pathを返す" do
        expect(helper.commit_log_tab_path).to eq(user_profile_path(user.id))
      end
    end

    context "params[:id]が存在しない場合" do
      it "profile_pathを返す" do
        expect(helper.commit_log_tab_path).to eq(profile_path)
      end
    end
  end

  describe "#likes_tab_path" do
    it "profile_likes_pathを返す" do
      expect(helper.likes_tab_path).to eq(profile_likes_path)
    end
  end

  describe "#commit_log_tab_active?" do
    before { params[:id] = user.id.to_s }

    it "commit logページで表示される場合、trueを返す" do
      allow(helper).to receive(:current_page?).with(user_profile_path(user.id)).and_return(true)
      expect(helper.commit_log_tab_active?).to be true
    end

    it "commit logページでない場合、falseを返す" do
      allow(helper).to receive(:current_page?).with(user_profile_path(user.id)).and_return(false)
      expect(helper.commit_log_tab_active?).to be false
    end
  end

  describe "#likes_tab_active?" do
    it "いいねページで表示される場合、trueを返す" do
      allow(helper).to receive(:current_page?).with(profile_likes_path).and_return(true)
      expect(helper.likes_tab_active?).to be true
    end

    it "いいねページでない場合、falseを返す" do
      allow(helper).to receive(:current_page?).with(profile_likes_path).and_return(false)
      expect(helper.likes_tab_active?).to be false
    end
  end
end
