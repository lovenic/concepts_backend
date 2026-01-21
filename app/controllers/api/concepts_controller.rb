module API
  class ConceptsController < BaseController
    def show
      concept = find_concept_by_id
      return if performed? # Early return if error was rendered
      render json: concept_to_json(concept)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Concept not found" }, status: :not_found
    end

    def like
      concept = find_concept_by_id
      return if performed? # Early return if error was rendered
      
      like = current_user.likes.find_by(concept_id: concept.id)
      
      if like
        like.destroy
        action = "unliked"
      else
        current_user.likes.create!(concept: concept)
        action = "liked"
      end

      render json: {
        success: true,
        action: action,
        concept: concept_to_json(concept)
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Concept not found" }, status: :not_found
    rescue StandardError => e
      Rails.logger.error "ConceptsController#like error: #{e.message}"
      render json: { error: "Failed to like concept", details: e.message }, status: :unprocessable_entity
    end

    def pin
      concept = find_concept_by_id
      return if performed? # Early return if error was rendered
      
      pin = current_user.pins.find_by(concept_id: concept.id)
      
      if pin
        pin.destroy
        action = "unpinned"
      else
        current_user.pins.create!(concept: concept)
        action = "pinned"
      end

      render json: {
        success: true,
        action: action,
        concept: concept_to_json(concept)
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Concept not found" }, status: :not_found
    rescue StandardError => e
      Rails.logger.error "ConceptsController#pin error: #{e.message}"
      render json: { error: "Failed to pin concept", details: e.message }, status: :unprocessable_entity
    end

    private

    def find_concept_by_id
      concept_id = params[:id].to_i
      if concept_id <= 0 || params[:id].to_s != concept_id.to_s
        render json: {
          error: "Invalid concept ID",
          code: "INVALID_CONCEPT_ID",
          details: { concept_id: params[:id] }
        }, status: :bad_request
        return nil
      end
      Concept.includes(:category, :user).find(concept_id)
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
