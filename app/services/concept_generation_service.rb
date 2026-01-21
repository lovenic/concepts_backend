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

      ## Concept Structure (7 fields):

      1. **hook** - A provocative question or statement that grabs attention
         - Should make the reader stop and think
         - Examples: "What if more choice makes you less happy?" or "The best decisions are made with incomplete information"
         - Max 150 characters

      2. **simple_definition** - Explain like I'm 12 years old
         - Simple, clear explanation without jargon
         - Use everyday words and relatable examples
         - Should make the concept immediately understandable
         - 2-3 sentences, max 250 characters

      3. **common_belief** - What most people think (the myth)
         - Start with "Most people think..." or "We're taught that..."
         - The conventional wisdom that will be challenged
         - Max 200 characters

      4. **reality** - The counterintuitive truth (the twist)
         - Start with "Actually..." or "In reality..."
         - The paradox or reversal that challenges the common belief
         - Why this feels wrong but is actually true
         - Max 300 characters

      5. **analogy** - Connection to another domain
         - "It's like in [domain], where..."
         - Helps understanding by linking to familiar concepts from different fields
         - Max 250 characters

      6. **mental_model** - A memorable framework or metaphor
         - A simple mental image or rule to remember this concept
         - "Think of it as..." or "Imagine..."
         - Max 200 characters

      7. **experiment** - A concrete action to test this yourself
         - Something the reader can try today or this week
         - Specific, actionable, measurable
         - "Try this: ..." or "Next time you..., notice..."
         - Max 250 characters

      ## Selection Criteria (MANDATORY):

      - **Counterintuitiveness**: The concept must feel wrong initially but be true
      - **Paradoxical depth**: Should reveal a paradox that illuminates truth
      - **Hidden mechanism**: Exposes something operating beneath the surface
      - **Fundamental reframing**: Changes how you see a whole category of things
      - **Non-obviousness**: NOT something from popular self-help or common knowledge
      #{@category ? "- **Category specificity**: MUST be specifically about #{category_name}" : ""}

      ## What to AVOID:

      - Surface-level concepts (growth mindset, compound interest, Pareto principle, etc.)
      - Obvious insights everyone already knows
      - Generic self-help advice
      - Vague or abstract experiments - must be concrete
      #{@category ? "- Generic concepts that could fit any category - it MUST be specifically about #{category_name}" : ""}

      ## Tone:

      - Direct and provocative
      - Intellectual but accessible
      - Challenges the reader
      - Reveals rather than explains

      #{@category ? "## FINAL CHECK - Category Alignment (MANDATORY):\n\nBefore finalizing, verify:\n1. Is this concept DIRECTLY about #{category_name}?\n2. Would an expert in #{category_name} recognize this as relevant to their field?\n3. Does it use #{category_name} terminology or reference #{category_name} principles?\n\nIf the answer to ANY of these is \"no\", STOP and reframe the concept to be specifically about #{category_name}.\n\n" : ""}IMPORTANT: Return ONLY a valid JSON object, no additional text or explanation. Use the following structure:
      {
        "title": "The concept title (concise, 3-8 words, hint at the twist)",
        "hook": "Provocative question or statement that grabs attention",
        "simple_definition": "Simple explanation as if explaining to a 12-year-old",
        "common_belief": "What most people think (the myth to be busted)",
        "reality": "The counterintuitive truth - the twist that challenges common belief",
        "analogy": "Connection to another domain that illuminates the concept",
        "mental_model": "A memorable framework or metaphor to remember this",
        "experiment": "A concrete action to test this yourself"
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
        hook: concept_data[:hook] || concept_data["hook"],
        simple_definition: concept_data[:simple_definition] || concept_data["simple_definition"],
        common_belief: concept_data[:common_belief] || concept_data["common_belief"],
        reality: concept_data[:reality] || concept_data["reality"],
        analogy: concept_data[:analogy] || concept_data["analogy"],
        mental_model: concept_data[:mental_model] || concept_data["mental_model"],
        experiment: concept_data[:experiment] || concept_data["experiment"]
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
