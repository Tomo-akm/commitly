require 'rails_helper'

RSpec.describe "Posts", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
  end

  describe "POST /posts" do
    context "通常投稿（general）の作成" do
      let(:valid_attributes) do
        {
          general_content: {
            content: "これはテスト投稿です"
          },
          post: {
            tag_names: "テスト, RSpec"
          }
        }
      end

      it "Postが1件増える" do
        expect {
          post posts_path, params: valid_attributes
        }.to change(Post, :count).by(1)
      end

      it "GeneralContentが1件増える" do
        expect {
          post posts_path, params: valid_attributes
        }.to change(GeneralContent, :count).by(1)
      end

      it "作成したPostがgeneral?を返す" do
        post posts_path, params: valid_attributes
        created_post = Post.last
        expect(created_post.general?).to be true
        expect(created_post.job_hunting?).to be false
      end

      it "contentableがGeneralContentである" do
        post posts_path, params: valid_attributes
        created_post = Post.last
        expect(created_post.contentable).to be_a(GeneralContent)
        expect(created_post.contentable.content).to eq("これはテスト投稿です")
      end

      it "タグが関連付けられる" do
        post posts_path, params: valid_attributes
        created_post = Post.last
        expect(created_post.tags.pluck(:name)).to contain_exactly("テスト", "rspec")
      end

      it "posts_pathにリダイレクトする" do
        post posts_path, params: valid_attributes
        expect(response).to redirect_to(posts_path)
      end
    end

    context "就活投稿（job_hunting）の作成" do
      let(:valid_attributes) do
        {
          type: 'job_hunting',
          job_hunting_content: {
            company_name: "株式会社テスト",
            selection_stage: "first_interview",
            result: "pending",
            content: "一次面接の感想です"
          }
        }
      end

      it "Postが1件増える" do
        expect {
          post posts_path, params: valid_attributes
        }.to change(Post, :count).by(1)
      end

      it "JobHuntingContentが1件増える" do
        expect {
          post posts_path, params: valid_attributes
        }.to change(JobHuntingContent, :count).by(1)
      end

      it "作成したPostがjob_hunting?を返す" do
        post posts_path, params: valid_attributes
        created_post = Post.last
        expect(created_post.job_hunting?).to be true
        expect(created_post.general?).to be false
      end

      it "contentableがJobHuntingContentである" do
        post posts_path, params: valid_attributes
        created_post = Post.last
        expect(created_post.contentable).to be_a(JobHuntingContent)
        expect(created_post.contentable.company_name).to eq("株式会社テスト")
        expect(created_post.contentable.selection_stage).to eq("first_interview")
        expect(created_post.contentable.result).to eq("pending")
      end

      it "企業名が自動的にタグとして追加される" do
        post posts_path, params: valid_attributes
        created_post = Post.last
        expect(created_post.tags.pluck(:name)).to include("テスト")
      end

      it "企業名から法人格が除去されてタグ化される" do
        post posts_path, params: {
          type: 'job_hunting',
          job_hunting_content: {
            company_name: "株式会社サンプル企業",
            selection_stage: "es",
            result: "pending",
            content: "ESを提出しました"
          }
        }
        created_post = Post.last
        expect(created_post.tags.pluck(:name)).to include("サンプル企業")
        expect(created_post.tags.pluck(:name)).not_to include("株式会社サンプル企業")
      end

      it "posts_pathにリダイレクトする" do
        post posts_path, params: valid_attributes
        expect(response).to redirect_to(posts_path)
      end
    end

    context "バリデーションエラー" do
      it "contentが空の場合はエラー" do
        expect {
          post posts_path, params: { general_content: { content: "" } }
        }.not_to change(Post, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "就活投稿でcompany_nameが空の場合はエラー" do
        expect {
          post posts_path, params: {
            type: 'job_hunting',
            job_hunting_content: {
              company_name: "",
              selection_stage: "es",
              result: "pending",
              content: "テスト"
            }
          }
        }.not_to change(Post, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /posts" do
    context "ransacker検索" do
      let!(:general_post) { create(:post, :general) }
      let!(:job_hunting_post) { create(:post, :job_hunting) }

      before do
        # contentを設定
        general_post.contentable.update(content: "Ruby on Railsのテスト")
        job_hunting_post.contentable.update(content: "面接でRubyについて質問された")
      end

      it "content_search_contで部分一致検索できる" do
        get posts_path, params: { q: { content_search_cont: "Ruby" } }
        expect(response).to have_http_status(:success)
        # ページに両方の投稿が含まれることを確認
        expect(response.body).to include("Ruby on Railsのテスト")
        expect(response.body).to include("面接でRubyについて質問された")
      end

      it "部分一致している投稿のみ検索できる" do
        get posts_path, params: { q: { content_search_cont: "Rails" } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Ruby on Railsのテスト")
        expect(response.body).not_to include("面接でRubyについて質問された")
      end
    end
  end
end
