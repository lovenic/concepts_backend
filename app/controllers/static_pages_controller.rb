class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!

  def home
  end

  def privacy
  end

  def terms
  end
end
