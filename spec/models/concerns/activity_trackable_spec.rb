# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityTrackable, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  describe '実績判定' do
    describe '単発実績' do
      describe 'first_post: 初投稿' do
        it '投稿を作成すると取得できる' do
          travel_to Time.zone.parse('2026-01-01 12:00:00') do
            create(:post, user: user)

            flags = user.achievement_flags
            history = user.achievement_history

            expect(flags[:first_post]).to be true
            expect(history[:first_post]).to be_present
            expect(history[:first_post].to_date).to eq Date.parse('2026-01-01')
          end
        end

        it '投稿がない場合は取得できない' do
          flags = user.achievement_flags
          expect(flags[:first_post]).to be false
        end
      end

      describe 'first_follow: 初フォロー' do
        it 'フォローすると取得できる' do
          other_user = create(:user)
          travel_to Time.zone.parse('2026-01-01 12:00:00') do
            create(:follow, follower: user, followed: other_user)

            flags = user.achievement_flags
            history = user.achievement_history

            expect(flags[:first_follow]).to be true
            expect(history[:first_follow]).to be_present
            expect(history[:first_follow].to_date).to eq Date.parse('2026-01-01')
          end
        end

        it 'フォローがない場合は取得できない' do
          flags = user.achievement_flags
          expect(flags[:first_follow]).to be false
        end
      end

      describe 'first_es_public: 初ES公開' do
        it 'ESを公開すると取得できる' do
          travel_to Time.zone.parse('2026-01-01 12:00:00') do
            create(:entry_sheet, user: user, shared_at: Time.current)

            flags = user.achievement_flags
            history = user.achievement_history

            expect(flags[:first_es_public]).to be true
            expect(history[:first_es_public]).to be_present
          end
        end

        it 'ESが公開されていない場合は取得できない' do
          create(:entry_sheet, user: user, shared_at: nil)

          flags = user.achievement_flags
          expect(flags[:first_es_public]).to be false
        end
      end

      describe 'first_review_request: 初#ESレビュー' do
        it '#ESレビュータグ付き投稿を作成すると取得できる' do
          travel_to Time.zone.parse('2026-01-01 12:00:00') do
            tag = Tag.find_or_create_by!(name: 'ESレビュー')
            post = create(:post, user: user)
            post.tags << tag

            flags = user.achievement_flags
            history = user.achievement_history

            expect(flags[:first_review_request]).to be true
            expect(history[:first_review_request]).to be_present
            expect(history[:first_review_request].to_date).to eq Date.parse('2026-01-01')
          end
        end

        it '#ESレビュータグがない場合は取得できない' do
          create(:post, user: user)

          flags = user.achievement_flags
          expect(flags[:first_review_request]).to be false
        end
      end
    end

    describe 'ストリーク実績' do
      describe 'streak_7: 7日連続' do
        it '7日連続で活動すると取得できる' do
          # 7日連続で投稿を作成
          7.times do |i|
            create(:post, user: user, created_at: Date.parse('2025-12-25') + i.days)
          end

          # データ作成後の日付にtravel_toして実績を確認
          travel_to Date.parse('2026-01-01') do
            flags = user.achievement_flags
            history = user.achievement_history

            expect(flags[:streak_7]).to be true
            expect(history[:streak_7]).to be_present
            expect(history[:streak_7].to_date).to eq Date.parse('2025-12-31')
          end
        end

        it '6日連続では取得できない' do
          6.times do |i|
            create(:post, user: user, created_at: Date.parse('2025-12-25') + i.days)
          end

          travel_to Date.parse('2026-01-01') do
            flags = user.achievement_flags
            expect(flags[:streak_7]).to be false
          end
        end
      end

      describe 'streak_14: 14日連続' do
        it '14日連続で活動すると取得できる' do
          14.times do |i|
            create(:post, user: user, created_at: Date.parse('2025-12-18') + i.days)
          end

          travel_to Date.parse('2026-01-01') do
            flags = user.achievement_flags
            expect(flags[:streak_14]).to be true
          end
        end
      end

      describe 'streak_30: 30日連続' do
        it '30日連続で活動すると取得できる' do
          30.times do |i|
            create(:post, user: user, created_at: Date.parse('2025-12-02') + i.days)
          end

          travel_to Date.parse('2026-01-01') do
            flags = user.achievement_flags
            expect(flags[:streak_30]).to be true
          end
        end
      end

      it 'ストリークが途切れても再カウントされる' do
        # 最初の7日連続
        7.times do |i|
          create(:post, user: user, created_at: Date.parse('2025-12-01') + i.days)
        end

        # 2日間途切れる
        # 2025-12-08, 2025-12-09 は活動なし

        # 再度7日連続
        7.times do |i|
          create(:post, user: user, created_at: Date.parse('2025-12-10') + i.days)
        end

        travel_to Date.parse('2026-01-01') do
          flags = user.achievement_flags
          # 両方の7日ストリークが記録される（最初の方が達成日）
          expect(flags[:streak_7]).to be true
        end
      end
    end

    describe '週間目標実績' do
      describe 'weekly_goal_1: 週3日達成を1週でクリア' do
        it '1週間で3日活動すると取得できる' do
          # 日曜始まりの週で3日活動（12月21日〜27日の週）
          create(:post, user: user, created_at: Date.parse('2025-12-21')) # 日曜
          create(:post, user: user, created_at: Date.parse('2025-12-23')) # 火曜
          create(:post, user: user, created_at: Date.parse('2025-12-25')) # 木曜

          travel_to Date.parse('2026-01-01') do
            flags = user.achievement_flags
            expect(flags[:weekly_goal_1]).to be true
          end
        end

        it '週2日では取得できない' do
          create(:post, user: user, created_at: Date.parse('2025-12-21'))
          create(:post, user: user, created_at: Date.parse('2025-12-23'))

          travel_to Date.parse('2026-01-01') do
            flags = user.achievement_flags
            expect(flags[:weekly_goal_1]).to be false
          end
        end
      end

      describe 'weekly_goal_2: 週3日達成を2週でクリア' do
        it '2週間でそれぞれ3日活動すると取得できる' do
          # 1週目（12月21日〜27日）
          create(:post, user: user, created_at: Date.parse('2025-12-21'))
          create(:post, user: user, created_at: Date.parse('2025-12-22'))
          create(:post, user: user, created_at: Date.parse('2025-12-23'))

          # 2週目（12月28日〜1月3日）
          create(:post, user: user, created_at: Date.parse('2025-12-28'))
          create(:post, user: user, created_at: Date.parse('2025-12-29'))
          create(:post, user: user, created_at: Date.parse('2025-12-30'))

          travel_to Date.parse('2026-01-05') do
            flags = user.achievement_flags
            expect(flags[:weekly_goal_2]).to be true
          end
        end
      end

      describe 'weekly_goal_3: 週3日達成を3週でクリア' do
        it '3週間でそれぞれ3日活動すると取得できる' do
          # 1週目（12月14日〜20日）
          create(:post, user: user, created_at: Date.parse('2025-12-14'))
          create(:post, user: user, created_at: Date.parse('2025-12-15'))
          create(:post, user: user, created_at: Date.parse('2025-12-16'))

          # 2週目（12月21日〜27日）
          create(:post, user: user, created_at: Date.parse('2025-12-21'))
          create(:post, user: user, created_at: Date.parse('2025-12-22'))
          create(:post, user: user, created_at: Date.parse('2025-12-23'))

          # 3週目（12月28日〜1月3日）
          create(:post, user: user, created_at: Date.parse('2025-12-28'))
          create(:post, user: user, created_at: Date.parse('2025-12-29'))
          create(:post, user: user, created_at: Date.parse('2025-12-30'))

          travel_to Date.parse('2026-01-05') do
            flags = user.achievement_flags
            expect(flags[:weekly_goal_3]).to be true
          end
        end
      end
    end

    describe '月間目標実績' do
      describe 'monthly_goal_1: 月10日達成を1ヶ月でクリア' do
        it '1ヶ月で10日活動すると取得できる' do
          10.times do |i|
            create(:post, user: user, created_at: Date.parse('2025-12-01') + (i * 2).days)
          end

          travel_to Date.parse('2026-01-01') do
            flags = user.achievement_flags
            expect(flags[:monthly_goal_1]).to be true
          end
        end

        it '9日では取得できない' do
          9.times do |i|
            create(:post, user: user, created_at: Date.parse('2025-12-01') + (i * 2).days)
          end

          travel_to Date.parse('2026-01-01') do
            flags = user.achievement_flags
            expect(flags[:monthly_goal_1]).to be false
          end
        end
      end

      describe 'monthly_goal_2: 月10日達成を2ヶ月でクリア' do
        it '2ヶ月でそれぞれ10日活動すると取得できる' do
          # 11月
          10.times do |i|
            create(:post, user: user, created_at: Date.parse('2025-11-01') + (i * 2).days)
          end

          # 12月
          10.times do |i|
            create(:post, user: user, created_at: Date.parse('2025-12-01') + (i * 2).days)
          end

          travel_to Date.parse('2026-01-01') do
            flags = user.achievement_flags
            expect(flags[:monthly_goal_2]).to be true
          end
        end
      end

      describe 'monthly_goal_3: 月10日達成を3ヶ月でクリア' do
        it '3ヶ月でそれぞれ10日活動すると取得できる' do
          # 10月
          10.times do |i|
            create(:post, user: user, created_at: Date.parse('2025-10-01') + (i * 2).days)
          end

          # 11月
          10.times do |i|
            create(:post, user: user, created_at: Date.parse('2025-11-01') + (i * 2).days)
          end

          # 12月
          10.times do |i|
            create(:post, user: user, created_at: Date.parse('2025-12-01') + (i * 2).days)
          end

          travel_to Date.parse('2026-01-01') do
            flags = user.achievement_flags
            expect(flags[:monthly_goal_3]).to be true
          end
        end
      end
    end

    describe 'ES公開実績' do
      describe 'es_public_3: 公開ES 3件' do
        it '3件公開すると取得できる' do
          3.times do |i|
            travel_to Time.zone.parse("2026-01-0#{i + 1} 12:00:00") do
              create(:entry_sheet, user: user, shared_at: Time.current)
            end
          end

          flags = user.achievement_flags
          expect(flags[:es_public_3]).to be true
        end

        it '2件では取得できない' do
          2.times { create(:entry_sheet, user: user, shared_at: Time.current) }

          flags = user.achievement_flags
          expect(flags[:es_public_3]).to be false
        end
      end

      describe 'es_public_5: 公開ES 5件' do
        it '5件公開すると取得できる' do
          5.times { create(:entry_sheet, user: user, shared_at: Time.current) }

          flags = user.achievement_flags
          expect(flags[:es_public_5]).to be true
        end
      end

      describe 'es_public_10: 公開ES 10件' do
        it '10件公開すると取得できる' do
          10.times { create(:entry_sheet, user: user, shared_at: Time.current) }

          flags = user.achievement_flags
          expect(flags[:es_public_10]).to be true
        end
      end
    end

    describe 'レビュー実績' do
      let(:review_tag) { Tag.find_or_create_by!(name: 'ESレビュー') }

      describe 'review_request_3: #ESレビュー 3回' do
        it '3回投稿すると取得できる' do
          3.times do
            post = create(:post, user: user)
            post.tags << review_tag
          end

          flags = user.achievement_flags
          expect(flags[:review_request_3]).to be true
        end

        it '2回では取得できない' do
          2.times do
            post = create(:post, user: user)
            post.tags << review_tag
          end

          flags = user.achievement_flags
          expect(flags[:review_request_3]).to be false
        end
      end

      describe 'review_request_5: #ESレビュー 5回' do
        it '5回投稿すると取得できる' do
          5.times do
            post = create(:post, user: user)
            post.tags << review_tag
          end

          flags = user.achievement_flags
          expect(flags[:review_request_5]).to be true
        end
      end

      describe 'review_request_10: #ESレビュー 10回' do
        it '10回投稿すると取得できる' do
          10.times do
            post = create(:post, user: user)
            post.tags << review_tag
          end

          flags = user.achievement_flags
          expect(flags[:review_request_10]).to be true
        end
      end
    end

    describe '相互フォロー実績' do
      describe 'mutual_follow_5: 相互フォロー 5人' do
        it '5人と相互フォローすると取得できる' do
          5.times do
            other_user = create(:user)
            create(:follow, follower: user, followed: other_user)
            create(:follow, follower: other_user, followed: user)
          end

          flags = user.achievement_flags
          expect(flags[:mutual_follow_5]).to be true
        end

        it '片方向フォローは含まれない' do
          5.times do
            other_user = create(:user)
            create(:follow, follower: user, followed: other_user)
            # 逆方向のフォローなし
          end

          flags = user.achievement_flags
          expect(flags[:mutual_follow_5]).to be false
        end
      end

      describe 'mutual_follow_10: 相互フォロー 10人' do
        it '10人と相互フォローすると取得できる' do
          10.times do
            other_user = create(:user)
            create(:follow, follower: user, followed: other_user)
            create(:follow, follower: other_user, followed: user)
          end

          flags = user.achievement_flags
          expect(flags[:mutual_follow_10]).to be true
        end
      end

      describe 'mutual_follow_20: 相互フォロー 20人' do
        it '20人と相互フォローすると取得できる' do
          20.times do
            other_user = create(:user)
            create(:follow, follower: user, followed: other_user)
            create(:follow, follower: other_user, followed: user)
          end

          flags = user.achievement_flags
          expect(flags[:mutual_follow_20]).to be true
        end
      end
    end

    describe 'テンプレート実績' do
      let(:available_tags) { EntrySheetItemTemplate::TAGS }

      describe 'template_3: テンプレート 3件' do
        it '3件作成すると取得できる' do
          3.times do |i|
            travel_to Time.zone.parse("2026-01-0#{i + 1} 12:00:00") do
              user.entry_sheet_item_templates.create!(
                tag: available_tags[i],
                title: "Title #{i}",
                content: "Content #{i}"
              )
            end
          end

          flags = user.achievement_flags
          expect(flags[:template_3]).to be true
        end

        it '2件では取得できない' do
          2.times do |i|
            user.entry_sheet_item_templates.create!(
              tag: available_tags[i],
              title: "Title #{i}",
              content: "Content #{i}"
            )
          end

          flags = user.achievement_flags
          expect(flags[:template_3]).to be false
        end
      end

      describe 'template_5: テンプレート 5件' do
        it '5件作成すると取得できる' do
          5.times do |i|
            user.entry_sheet_item_templates.create!(
              tag: available_tags[i],
              title: "Title #{i}",
              content: "Content #{i}"
            )
          end

          flags = user.achievement_flags
          expect(flags[:template_5]).to be true
        end
      end

      describe 'template_7: テンプレート 7件' do
        it '7件作成すると取得できる' do
          7.times do |i|
            user.entry_sheet_item_templates.create!(
              tag: available_tags[i],
              title: "Title #{i}",
              content: "Content #{i}"
            )
          end

          flags = user.achievement_flags
          expect(flags[:template_7]).to be true
        end
      end
    end

    describe '企業トラッカー実績' do
      describe 'company_progress_3: 企業別進捗 3社' do
        it '3社の就活投稿を作成すると取得できる' do
          3.times do |i|
            content = create(:job_hunting_content, company_name: "Company #{i}")
            create(:post, user: user, contentable: content)
          end

          flags = user.achievement_flags
          expect(flags[:company_progress_3]).to be true
        end

        it '同じ企業の重複投稿はカウントされない' do
          3.times do
            content = create(:job_hunting_content, company_name: "Same Company")
            create(:post, user: user, contentable: content)
          end

          flags = user.achievement_flags
          expect(flags[:company_progress_3]).to be false
        end
      end

      describe 'company_progress_5: 企業別進捗 5社' do
        it '5社の就活投稿を作成すると取得できる' do
          5.times do |i|
            content = create(:job_hunting_content, company_name: "Company #{i}")
            create(:post, user: user, contentable: content)
          end

          flags = user.achievement_flags
          expect(flags[:company_progress_5]).to be true
        end
      end

      describe 'company_progress_7: 企業別進捗 7社' do
        it '7社の就活投稿を作成すると取得できる' do
          7.times do |i|
            content = create(:job_hunting_content, company_name: "Company #{i}")
            create(:post, user: user, contentable: content)
          end

          flags = user.achievement_flags
          expect(flags[:company_progress_7]).to be true
        end
      end
    end
  end
end