class DailyLibraryGenerationJob < ApplicationJob
  queue_as :default

  DAILY_CONCEPT_COUNT = 3

  def perform
    category_ids = Category.pluck(:id).sample(DAILY_CONCEPT_COUNT)

    if category_ids.empty?
      Rails.logger.warn "DailyLibraryGenerationJob: Skipping generation because no categories exist"
      return
    end

    category_ids.each do |category_id|
      category = Category.find_by(id: category_id)
      next unless category

      ConceptGenerationService.new(category: category).call
    end

    Rails.logger.info "DailyLibraryGenerationJob: Created #{category_ids.size} library concepts"
  end
end
