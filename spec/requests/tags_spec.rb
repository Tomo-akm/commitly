require 'rails_helper'

RSpec.describe "Tags", type: :request do
  describe "GET /tags/autocomplete" do
    context "クエリパラメータqで検索" do
      before do
        # r で始まるタグ
        Tag.create!(name: "rails", posts_count: 10)
        Tag.create!(name: "ruby", posts_count: 20)
        Tag.create!(name: "rust", posts_count: 5)
        # r で始まらないタグ
        Tag.create!(name: "javascript", posts_count: 15)
        Tag.create!(name: "python", posts_count: 8)
      end

      it "前方一致するタグのみを返す" do
        get autocomplete_tags_path, params: { q: "r" }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)
        tag_names = json.map { |tag| tag["name"] }
        expect(tag_names).to contain_exactly("rails", "ruby", "rust")
      end

      it "大文字小文字を区別せずに検索する" do
        get autocomplete_tags_path, params: { q: "R" }

        json = JSON.parse(response.body)
        tag_names = json.map { |tag| tag["name"] }
        expect(tag_names).to contain_exactly("rails", "ruby", "rust")
      end

      it "posts_count降順でソートされる" do
        get autocomplete_tags_path, params: { q: "r" }

        json = JSON.parse(response.body)
        tag_names = json.map { |tag| tag["name"] }
        expect(tag_names).to eq([ "ruby", "rails", "rust" ])
      end

      it "完全一致でも検索できる" do
        get autocomplete_tags_path, params: { q: "rails" }

        json = JSON.parse(response.body)
        tag_names = json.map { |tag| tag["name"] }
        expect(tag_names).to contain_exactly("rails")
      end

      it "空文字の場合は全てのタグを返す" do
        get autocomplete_tags_path, params: { q: "" }

        json = JSON.parse(response.body)
        tag_names = json.map { |tag| tag["name"] }
        # このコンテキストで作成した5つのタグを含む
        expect(tag_names).to include("rails", "ruby", "rust", "javascript", "python")
      end

      it "マッチしない場合は空配列を返す" do
        get autocomplete_tags_path, params: { q: "golang" }

        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end

    context "最大件数制限" do
      before do
        # さらに多くのタグを追加
        (1..15).each do |i|
          Tag.create!(name: "react#{i}", posts_count: i)
        end
      end

      it "最大10件まで返す" do
        get autocomplete_tags_path, params: { q: "react" }

        json = JSON.parse(response.body)
        expect(json.size).to eq(10)
      end

      it "posts_count降順で上位10件を返す" do
        get autocomplete_tags_path, params: { q: "react" }

        json = JSON.parse(response.body)
        tag_names = json.map { |tag| tag["name"] }
        # posts_countが高い順（react15, react14, ..., react6）
        expect(tag_names.first).to eq("react15")
        expect(tag_names.last).to eq("react6")
      end
    end

    context "日本語タグの検索" do
      before do
        Tag.create!(name: "テスト", posts_count: 5)
        Tag.create!(name: "テストケース", posts_count: 3)
        Tag.create!(name: "実装", posts_count: 7)
      end

      it "日本語でも前方一致検索できる" do
        get autocomplete_tags_path, params: { q: "テスト" }

        json = JSON.parse(response.body)
        tag_names = json.map { |tag| tag["name"] }
        expect(tag_names).to contain_exactly("テスト", "テストケース")
      end
    end
  end

  describe "公開範囲機能" do
    describe "GET /tags/:id (タグ検索での表示制御)" do
      let!(:tag) { create(:tag, name: "Ruby") }
      let!(:viewer) { create(:user) }
      let!(:public_user) { create(:user, post_visibility: :everyone) }
      let!(:mutual_user) { create(:user, post_visibility: :mutual_followers) }
      let!(:private_user) { create(:user, post_visibility: :only_me) }

      let!(:public_post) { create(:post, user: public_user) }
      let!(:mutual_post) { create(:post, user: mutual_user) }
      let!(:private_post) { create(:post, user: private_user) }
      let!(:own_post) { create(:post, user: viewer) }

      before do
        # 全ての投稿にタグを追加
        public_post.tags << tag
        mutual_post.tags << tag
        private_post.tags << tag
        own_post.tags << tag

        sign_in viewer
      end

      context 'フォロー関係がない場合' do
        it '全体公開の投稿と自分の投稿のみ表示される' do
          get tag_path(tag)
          expect(response).to have_http_status(:success)
          expect(response.body).to include(public_post.contentable.content)
          expect(response.body).to include(own_post.contentable.content)
          expect(response.body).not_to include(mutual_post.contentable.content)
          expect(response.body).not_to include(private_post.contentable.content)
        end
      end

      context '相互フォロー関係がある場合' do
        before do
          viewer.follow(mutual_user)
          mutual_user.follow(viewer)
        end

        it '全体公開、相互フォロー、自分の投稿が表示される' do
          get tag_path(tag)
          expect(response).to have_http_status(:success)
          expect(response.body).to include(public_post.contentable.content)
          expect(response.body).to include(mutual_post.contentable.content)
          expect(response.body).to include(own_post.contentable.content)
          expect(response.body).not_to include(private_post.contentable.content)
        end
      end

      context '自分の投稿が自分だけ設定の場合' do
        before do
          viewer.update(post_visibility: :only_me)
        end

        it '自分の投稿は表示される' do
          get tag_path(tag)
          expect(response).to have_http_status(:success)
          expect(response.body).to include(own_post.contentable.content)
        end
      end

      context '投稿数のカウント' do
        it '閲覧可能な投稿数のみカウントされる' do
          get tag_path(tag)
          expect(response).to have_http_status(:success)
          # 全体公開 + 自分の投稿 = 2件
          expect(response.body).to include('2件の投稿')
        end
      end
    end
  end
end
