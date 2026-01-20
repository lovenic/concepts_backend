module API
  class CategoriesController < BaseController
    def index
      categories = Category.roots
      
      render json: categories.map { |category| category_to_json(category) }
    end

    private

    def category_to_json(category)
      {
        id: category.id,
        name: category.name,
        slug: category.slug,
        subcategories: category.children.map { |sub| category_to_json(sub) }
      }
    end
  end
end
