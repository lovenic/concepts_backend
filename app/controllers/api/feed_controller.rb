module API
  class FeedController < BaseController
    def index
      concepts = Concept.includes(:category, :user)

      # Filter by category
      if params[:category_id].present?
        category = Category.find_by(id: params[:category_id])
        if category
          # Include concepts from this category and all its subcategories
          category_ids = [category.id] + category.descendant_ids
          concepts = concepts.where(category_id: category_ids)
        end
      end

      # Apply filter (hot or new)
      case params[:filter]&.to_sym
      when :hot
        period = params[:period]&.to_sym || :daily
        concepts = concepts.hot(period)
      when :new
        concepts = concepts.newest
      else
        concepts = concepts.newest
      end

      # Pagination
      page = params[:page]&.to_i || 1
      per_page = [params[:per_page]&.to_i || 20, 100].min # Cap at 100
      concepts = concepts.page(page).per(per_page)

      # Preload parent categories to avoid N+1 queries
      preload_parent_categories(concepts)

      render json: {
        concepts: concepts.map { |concept| concept_to_json(concept) },
        pagination: {
          page: page,
          per_page: per_page,
          total_pages: concepts.total_pages,
          total_count: concepts.total_count
        }
      }
    end

    def generate
      # Validate category_id if provided
      if params[:category_id].present?
        category = Category.find_by(id: params[:category_id])
        unless category
          return render json: {
            error: "Category not found",
            code: "CATEGORY_NOT_FOUND",
            details: { category_id: params[:category_id] }
          }, status: :not_found
        end
      end

      # Check rate limit before calling ChatGPT (save API calls)
      unless current_user.can_generate_concept?
        remaining = current_user.remaining_daily_concepts
        return render json: {
          error: "Daily limit exceeded",
          code: "RATE_LIMIT_EXCEEDED",
          details: {
            limit: User::DAILY_CONCEPT_LIMIT,
            remaining: remaining,
            message: "You've reached your daily limit of #{User::DAILY_CONCEPT_LIMIT} concepts. Take a moment to explore amazing concepts created by our community!"
          }
        }, status: :too_many_requests
      end

      category = params[:category_id].present? ? Category.find_by(id: params[:category_id]) : nil

      service = ConceptGenerationService.new(user: current_user, category: category)
      concept = service.call

      current_user.increment_daily_concepts_count!

      # Reload concept with category to ensure it's properly loaded
      concept.reload

      render json: concept_to_json(concept), status: :created
    rescue StandardError => e
      Rails.logger.error "FeedController#generate error: #{e.message}"
      error_code = case e.message
                   when /parse|JSON/i
                     "CHATGPT_PARSE_ERROR"
                   when /unavailable|service/i
                     "CHATGPT_UNAVAILABLE"
                   else
                     "GENERATION_ERROR"
                   end
      render json: {
        error: "Failed to generate concept",
        code: error_code,
        details: { message: e.message }
      }, status: :unprocessable_entity
    end

    private

    def preload_parent_categories(concepts)
      # Collect all unique ancestry paths from categories
      ancestry_paths = concepts.map { |c| c.category.ancestry }.compact.uniq
      
      # Extract parent IDs from ancestry paths
      parent_ids = ancestry_paths.flat_map do |path|
        path.split('/').map(&:to_i)
      end.uniq
      
      # Preload all parent categories
      Category.where(id: parent_ids).load if parent_ids.any?
    end

    def concept_to_json(concept)
      category_data = {
        id: concept.category.id,
        name: concept.category.name,
        slug: concept.category.slug
      }
      
      # Add parent category info if this is a subcategory
      if concept.category.parent.present?
        category_data[:parent_category] = {
          id: concept.category.parent.id,
          name: concept.category.parent.name,
          slug: concept.category.parent.slug
        }
      end
      
      {
        id: concept.id,
        title: concept.title,
        category: category_data,
        body: concept.body,
        likes_count: concept.likes_count,
        pins_count: concept.pins_count,
        liked: concept.liked_by?(current_user),
        pinned: concept.pinned_by?(current_user),
        created_at: concept.created_at.iso8601,
        user: concept.user ? {
          id: concept.user.id,
          name: concept.user.name || concept.user.email
        } : nil
      }
    end
  end
end
