class ConceptGenerationService
  def initialize(user:, category: nil)
    @user = user
    @category = category
  end

  def call
    # Handle missing category gracefully
    if @category && !@category.persisted?
      raise StandardError, "Category is invalid"
    end

    # Fallback to random category if provided category doesn't exist
    # Do this BEFORE formatting category_name so the prompt knows the actual category
    if @category.nil? && Category.count > 0
      @category = Category.all.sample
    end

    # Format category name for prompt: "Category / Subcategory" if subcategory
    category_name = if @category
      if @category.parent.present?
        "#{@category.parent.name} / #{@category.name}"
      else
        @category.name
      end
    else
      "any field of knowledge"
    end
    
    category_context = if @category
      "\n\n## ⚠️ CRITICAL: Category Requirement - THIS IS MANDATORY ⚠️\n\nYou MUST generate a concept that is DIRECTLY and SPECIFICALLY about #{category_name}. This is NOT optional.\n\nREQUIREMENTS:\n- The concept MUST be fundamentally about #{category_name} or its specific subfields\n- It MUST draw from #{category_name} principles, theories, practices, or domain knowledge\n- It MUST NOT be a generic concept that could apply to any category\n- An expert in #{category_name} would immediately recognize this as belonging to their field\n\n❌ WRONG EXAMPLES (concepts that don't belong to #{category_name}):\n- \"Success through mistakes\" - this is Psychology/Education, NOT #{category_name}\n- \"Embracing uncertainty\" - this is Philosophy/Personal Development, NOT #{category_name}\n- \"Constraints increase creativity\" - this is Psychology/Design, NOT #{category_name}\n- Any concept about learning, personal growth, or general life advice when #{category_name} is Technology, Science, or Business\n\n✅ CORRECT: The concept must use #{category_name} terminology, reference #{category_name} theories, or reveal something specific about how #{category_name} systems work.\n\nBefore generating, ask yourself: \"Would this concept appear in a #{category_name} textbook, research paper, or professional discussion?\" If the answer is no, reframe it to be specifically about #{category_name}."
    else
      ""
    end

    prompt = <<~PROMPT
      You are a mentor who reveals mind-bending, counterintuitive concepts that fundamentally challenge how people think about reality, themselves, and the world.
      
      #{@category ? "**🎯 TARGET CATEGORY: #{category_name} 🎯**\n\n⚠️ CRITICAL: You are generating a concept SPECIFICALLY for the category: #{category_name}.\n\nThis is NOT optional - the concept MUST be directly related to #{category_name}.\n\nDO NOT generate:\n- Generic concepts about learning, personal growth, or life advice\n- Concepts that could fit in Philosophy, Psychology, or Personal Development when #{category_name} is Technology, Science, or Business\n- Universal principles that apply to any field\n\nThe concept MUST be about #{category_name} specifically - use #{category_name} terminology, reference #{category_name} theories, or reveal something about how #{category_name} systems work.\n\n" : ""}

      ## CRITICAL REQUIREMENTS:

      Generate a MIND-BENDING concept#{category_context} that:
      
      - **Challenges fundamental assumptions** - not just "interesting" but genuinely counterintuitive
      - **Reveals hidden patterns** - shows connections that are not obvious at first glance
      - **Inverts common wisdom** - flips "obvious" truths on their head
      - **Exposes paradoxes** - embraces contradictions that reveal deeper truths
      - **Is NOT surface-level** - avoid concepts everyone already knows (like "growth mindset", "compound interest", etc.)
      - **Is genuinely surprising** - should make someone think "wait, that can't be right... but it is!"

      ## Concept Format:

      1. **Short Definition** (as for an intelligent 15-year-old)
         - Simple language, without academic overload
         - With a clear metaphor or example
         - Maximum 2-4 sentences
         - Should hint at the counterintuitive nature

      2. **Deep Twist** (the mind-bending revelation)
         - The specific way this concept flips conventional understanding
         - The paradox or contradiction it reveals
         - Why this feels wrong but is actually true
         - The "aha!" moment that changes everything
         - Must be genuinely surprising, not just "interesting"

      3. **Practical Implementation**
         - How this reframing changes decision-making
         - Concrete ways to apply this counterintuitive insight
         - What behaviors or thoughts this should change
         - Why most people get this wrong

      ## Selection Criteria (MANDATORY):

      - **Counterintuitiveness**: The concept must feel wrong initially but be true
      - **Paradoxical depth**: Should reveal a paradox that illuminates truth
      - **Hidden mechanism**: Exposes something operating beneath the surface
      - **Fundamental reframing**: Changes how you see a whole category of things
      - **Non-obviousness**: NOT something from popular self-help or common knowledge
      - **Mind-bending quality**: Should genuinely surprise and challenge assumptions

      ## What to AVOID:

      - Surface-level concepts (growth mindset, compound interest, Pareto principle, etc.)
      - Obvious insights everyone already knows
      - Generic self-help advice
      - Concepts that don't challenge fundamental assumptions
      - Things that are "interesting" but not mind-bending
      #{@category ? "- Generic concepts that could fit any category - it MUST be specifically about #{category_name}" : ""}

      ## Tone:

      - Direct and provocative
      - Intellectual but accessible
      - Challenges the reader
      - Reveals rather than explains

      #{@category ? "## FINAL CHECK - Category Alignment (MANDATORY):\n\nBefore finalizing, verify:\n1. Is this concept DIRECTLY about #{category_name}?\n2. Would an expert in #{category_name} recognize this as relevant to their field?\n3. Could this concept appear in a #{category_name} textbook or research paper?\n4. Does it use #{category_name} terminology or reference #{category_name} principles?\n5. If you removed the #{category_name} context, would it still make sense? (If yes, it's too generic - WRONG)\n\nIf the answer to ANY of these is \"no\", STOP and reframe the concept to be specifically about #{category_name}. Do NOT generate a generic concept.\n\n" : ""}IMPORTANT: Return ONLY a valid JSON object, no additional text or explanation. The concept MUST be genuinely mind-bending and counterintuitive#{@category ? " AND must be directly related to #{category_name} - NOT a generic concept that could fit any category" : ""}. Use the following structure:
      {
        "title": "The concept title (concise, 3-8 words, hint at the twist)",
        "short_definition": "A brief definition that hints at the counterintuitive nature (1-2 sentences, max 200 characters)",
        "deep_twist": "The specific mind-bending revelation - how it flips understanding, the paradox it reveals, why it feels wrong but is true (2-4 sentences, max 400 characters)",
        "practical_implementation": "How to apply this counterintuitive insight in daily life (2-4 sentences, max 400 characters)",
        "examples": ["Example 1", "Example 2"],
        "related_concepts": ["Related concept 1", "Related concept 2"],
        "difficulty_level": "beginner|intermediate|advanced"
      }
    PROMPT

    # Log the prompt to console for debugging
    Rails.logger.info "=" * 80
    Rails.logger.info "CONCEPT GENERATION PROMPT:"
    Rails.logger.info "=" * 80
    Rails.logger.info prompt
    Rails.logger.info "=" * 80
    puts "=" * 80
    puts "CONCEPT GENERATION PROMPT:"
    puts "=" * 80
    puts prompt
    puts "=" * 80

    response = AI::ChatGPTQuery.new(prompt: prompt, is_json: true).call

    concept_data = response.is_a?(Hash) ? response : response.first

    # Category should already be set at this point (either provided or randomly selected)
    assigned_category = @category
    Rails.logger.info "ConceptGenerationService: Assigning category #{assigned_category.id} (#{assigned_category.name}) to concept"

    concept = @user.concepts.create!(
      title: concept_data[:title] || concept_data["title"],
      category: assigned_category,
      body: {
        short_definition: concept_data[:short_definition] || concept_data["short_definition"],
        deep_twist: concept_data[:deep_twist] || concept_data["deep_twist"],
        practical_implementation: concept_data[:practical_implementation] || concept_data["practical_implementation"],
        examples: concept_data[:examples] || concept_data["examples"] || [],
        related_concepts: concept_data[:related_concepts] || concept_data["related_concepts"] || [],
        difficulty_level: concept_data[:difficulty_level] || concept_data["difficulty_level"] || "intermediate"
      }
    )

    # Verify category was assigned correctly
    concept.reload
    Rails.logger.info "ConceptGenerationService: Concept #{concept.id} created with category #{concept.category.id} (#{concept.category.name})"

    concept
  rescue JSON::ParserError => e
    Rails.logger.error "ConceptGenerationService JSON parse error: #{e.message}"
    raise StandardError, "Failed to parse AI response. Please try again."
  rescue StandardError => e
    Rails.logger.error "ConceptGenerationService error: #{e.message}"
    raise e
  end
end
