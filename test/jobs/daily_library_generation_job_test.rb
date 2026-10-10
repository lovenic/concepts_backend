require "test_helper"

class DailyLibraryGenerationJobTest < Minitest::Test
  def test_creates_one_library_concept_for_each_randomly_selected_category
    selected_category_ids = [ 11, 12, 13, 14, 15 ]
    generated_category_ids = []

    stub_class_method(Category, :pluck, ->(*) { selected_category_ids }) do
      stub_class_method(Category, :find_by, ->(id:) { Struct.new(:id, :name).new(id, "Category #{id}") }) do
        stub_class_method(ConceptGenerationService, :new, ->(user: nil, category:) {
          generated_category_ids << category.id
          Object.new.tap { |generator| generator.define_singleton_method(:call) { nil } }
        }) do
          DailyLibraryGenerationJob.new.perform
        end
      end
    end

    assert_equal selected_category_ids.sort, generated_category_ids.sort
  end

  def test_does_not_create_concepts_when_there_are_no_categories
    stub_class_method(Category, :pluck, ->(*) { [] }) do
      stub_class_method(ConceptGenerationService, :new, ->(*) { flunk "should not initialize the generator" }) do
        DailyLibraryGenerationJob.new.perform
      end
    end
  end

  private

  def stub_class_method(klass, method_name, replacement)
    original = klass.method(method_name)
    klass.define_singleton_method(method_name, &replacement)
    yield
  ensure
    klass.define_singleton_method(method_name, &original)
  end
end
