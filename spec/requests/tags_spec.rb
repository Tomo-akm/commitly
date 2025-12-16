require 'rails_helper'

RSpec.describe "Tags", type: :request do
  describe "GET /tags/autocomplete" do
    before do
      Tag.delete_all
    end

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
        expect(json).to contain_exactly("rails", "ruby", "rust")
      end

      it "大文字小文字を区別せずに検索する" do
        get autocomplete_tags_path, params: { q: "R" }

        json = JSON.parse(response.body)
        expect(json).to contain_exactly("rails", "ruby", "rust")
      end

      it "posts_count降順でソートされる" do
        get autocomplete_tags_path, params: { q: "r" }

        json = JSON.parse(response.body)
        expect(json).to eq([ "ruby", "rails", "rust" ])
      end

      it "完全一致でも検索できる" do
        get autocomplete_tags_path, params: { q: "rails" }

        json = JSON.parse(response.body)
        expect(json).to contain_exactly("rails")
      end

      it "空文字の場合は全てのタグを返す" do
        get autocomplete_tags_path, params: { q: "" }

        json = JSON.parse(response.body)
        expect(json.size).to eq(5)
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
        # posts_countが高い順（react15, react14, ..., react6）
        expect(json.first).to eq("react15")
        expect(json.last).to eq("react6")
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
        expect(json).to contain_exactly("テスト", "テストケース")
      end
    end
  end
end
