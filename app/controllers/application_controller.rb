class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?
  helper Settings::NavigationHelper

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  def set_right_nav_data
    set_popular_tags
    set_vault_summary
  end

  def set_popular_tags
    visible_post_ids = Post.visible_to(current_user).pluck(:id)
    @popular_tags = Tag.joins(:posts)
                       .where(posts: { id: visible_post_ids })
                       .group("tags.id")
                       .select("tags.*, COUNT(posts.id) AS visible_posts_count")
                       .order("COUNT(posts.id) DESC")
                       .limit(10)
  end

  def set_vault_summary
    return unless user_signed_in?

    entry_sheets = current_user.entry_sheets
    @vault_es_count = entry_sheets.count
    company_progress = fetch_company_progress(current_user)
    @vault_progress_companies = company_progress.select do |company|
      company[:result] != "failed" && !(company[:selection_stage] == "final_interview" && company[:result] == "passed")
    end
    @vault_progress_company_count = @vault_progress_companies.size
  end

  def fetch_company_progress(user)
    job_hunting_posts = user.posts
                            .job_hunting
                            .includes(:contentable)
                            .order(created_at: :desc)

    company_data = {}
    job_hunting_posts.each do |post|
      content = post.contentable
      company_name = content.normalized_company_name
      next if company_name.blank?

      if company_data[company_name].nil? || company_data[company_name][:updated_at] < post.created_at
        company_data[company_name] = {
          company_name: content.company_name,
          normalized_name: company_name,
          selection_stage: content.selection_stage,
          selection_stage_ja: content.selection_stage_ja,
          result: content.result,
          result_ja: content.result_ja,
          updated_at: post.created_at
        }
      end
    end

    company_data.values.sort_by { |data| data[:updated_at] }.reverse
  end
end
