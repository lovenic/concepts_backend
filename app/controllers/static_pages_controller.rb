class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!

  def home
    # Fetch all categories and subcategories for the horizontal feed
    @categories = Category.roots
    @all_categories = Category.all.order(:name) # Flattened list for the feed
    @users_count = User.count
  end

  def privacy
  end

  def terms
  end

  def help
  end
end
