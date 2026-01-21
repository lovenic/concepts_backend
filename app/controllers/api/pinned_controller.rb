module API
  class PinnedController < BaseController
    def index
      pins = current_user.pins.includes(concept: :user)

      # Filter by category
      if params[:category_id].present?
        category = Category.find_by(id: params[:category_id])
        if category
          category_ids = [category.id] + category.descendant_ids
          pins = pins.joins(:concept).where(concepts: { category_id: category_ids })
        end
      end

      # Order by created_at desc (most recent first)
      pins = pins.order(created_at: :desc)

      # Pagination
      page = params[:page]&.to_i || 1
      per_page = [params[:per_page]&.to_i || 20, 100].min
      pins = pins.page(page).per(per_page)

      concepts = pins.map(&:concept)

      # Preload parent categories to avoid N+1 queries
      preload_parent_categories(concepts)

      render json: {
        concepts: concepts.map { |concept| concept_to_json(concept) },
        pagination: {
          page: page,
          per_page: per_page,
          total_pages: pins.total_pages,
          total_count: pins.total_count
        }
      }
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
        pinned: true, # Always true in pinned controller
        created_at: concept.created_at.iso8601,
        pinned_at: current_user.pins.find_by(concept_id: concept.id)&.created_at&.iso8601,
        user: concept.user ? {
          id: concept.user.id,
          name: concept.user.name || concept.user.email
        } : nil
      }
    end
  end
end
