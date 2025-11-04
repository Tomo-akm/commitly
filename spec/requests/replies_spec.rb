require 'rails_helper'

RSpec.describe "Replies", type: :request do
  # --- 1. テストデータの準備 ---
  # let を使って、テストに必要なユーザー、投稿、返信を準備します
  let(:user) { create(:user) }
  let(:post_record) { create(:post, user: user) } # 投稿 (post だと 'post' メソッドと被るので post_record に)
  
  # 'let!' を使うと、it ブロックの実行前にデータが作成されます
  let!(:reply_to_delete) { create(:reply, user: user, post: post_record) } 

  # --- 2. 認証 ---
  # create や destroy はログインが必要なはずなので、
  # 各テストの実行前に 'user' としてログインさせます
  before do
    sign_in(user) # Devise のテストヘルパーを想定
  end

  # --- 3. create アクションのテスト ---
  describe "POST /posts/:post_id/replies" do # 正しくは POST
    context "有効なパラメータの場合" do
      it "リプライが1件増えること" do
        # post メソッドでリクエストを送信
        # expect { ... }.to change(Model, :count).by(X) は
        # 「... の処理を実行したら、Model の数が X 増減すること」を検証する
        expect {
          post post_replies_path(post_record), params: { 
            reply: { content: "This is a new reply" } 
          }
        }.to change(Reply, :count).by(1)
      end

      it "投稿詳細ページにリダイレクトすること" do
        post post_replies_path(post_record), params: { 
          reply: { content: "This is a new reply" } 
        }
        # 成功後は :success (2xx) ではなく、:redirect (3xx) を期待する
        expect(response).to have_http_status(:redirect)
        # どこにリダイレクトしたかも検証する
        expect(response).to redirect_to(post_path(post_record))
      end
    end

    context "無効なパラメータの場合" do
      it "リプライが増えないこと" do
        expect {
          post post_replies_path(post_record), params: { 
            reply: { content: "" } # わざと content を空にする
          }
        }.to change(Reply, :count).by(0) # 0 = 増えない
      end
    end
  end

  # --- 4. destroy アクションのテスト ---
  describe "DELETE /replies/:id" do 
    it "リプライが1件減ること" do
      # delete メソッドでリクエストを送信
      expect {
        delete post_reply_path(post_record, reply_to_delete)
      }.to change(Reply, :count).by(-1)
    end
    it "投稿詳細ページにリダイレクトすること" do
      delete post_reply_path(post_record, reply_to_delete)
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(post_path(post_record))
    end
  end
end
