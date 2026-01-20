# Seed Categories with subcategories
# Root categories are broad and understandable, subcategories are more specific

# Clear existing categories to prevent duplicates on re-seeding
Category.destroy_all

# Philosophy
philosophy = Category.create!(name: "Philosophy", slug: "philosophy")
Category.create!(name: "Stoicism", slug: "stoicism", parent: philosophy)
Category.create!(name: "Existentialism", slug: "existentialism", parent: philosophy)
Category.create!(name: "Eastern Philosophy", slug: "eastern-philosophy", parent: philosophy)
Category.create!(name: "Ethics", slug: "ethics", parent: philosophy)
Category.create!(name: "Phenomenology", slug: "phenomenology", parent: philosophy)
Category.create!(name: "Semiotics", slug: "semiotics", parent: philosophy)

# Science
science = Category.create!(name: "Science", slug: "science")
Category.create!(name: "Physics", slug: "physics", parent: science)
Category.create!(name: "Mathematics", slug: "mathematics", parent: science)
Category.create!(name: "Probability Theory", slug: "probability-theory", parent: science)
Category.create!(name: "Game Theory", slug: "game-theory", parent: science)
Category.create!(name: "Information Theory", slug: "information-theory", parent: science)
Category.create!(name: "Complexity Theory", slug: "complexity-theory", parent: science)
Category.create!(name: "Category Theory", slug: "category-theory", parent: science)
Category.create!(name: "Cybernetics", slug: "cybernetics", parent: science)
Category.create!(name: "Cognitive Science", slug: "cognitive-science", parent: science)
Category.create!(name: "Neuroscience", slug: "neuroscience", parent: science)
Category.create!(name: "Neuroaesthetics", slug: "neuroaesthetics", parent: science)
Category.create!(name: "Evolutionary Psychology", slug: "evolutionary-psychology", parent: science)

# Technology
technology = Category.create!(name: "Technology", slug: "technology")
Category.create!(name: "Software Development", slug: "software-development", parent: technology)
Category.create!(name: "Artificial Intelligence", slug: "artificial-intelligence", parent: technology)
Category.create!(name: "Machine Learning", slug: "machine-learning", parent: technology)
Category.create!(name: "Robotics", slug: "robotics", parent: technology)
Category.create!(name: "Computer Science", slug: "computer-science", parent: technology)
Category.create!(name: "Human-Computer Interaction", slug: "human-computer-interaction", parent: technology)
Category.create!(name: "Cybersecurity", slug: "cybersecurity", parent: technology)
Category.create!(name: "Data Science", slug: "data-science", parent: technology)

# Business & Economics
business = Category.create!(name: "Business & Economics", slug: "business-economics")
Category.create!(name: "Economics", slug: "economics", parent: business)
Category.create!(name: "Microeconomics", slug: "microeconomics", parent: business)
Category.create!(name: "Entrepreneurship", slug: "entrepreneurship", parent: business)
Category.create!(name: "Marketing", slug: "marketing", parent: business)
Category.create!(name: "Finance", slug: "finance", parent: business)
Category.create!(name: "Management", slug: "management", parent: business)

# Psychology
psychology = Category.create!(name: "Psychology", slug: "psychology")
Category.create!(name: "Cognitive Psychology", slug: "cognitive-psychology", parent: psychology)
Category.create!(name: "Behavioral Psychology", slug: "behavioral-psychology", parent: psychology)
Category.create!(name: "Social Psychology", slug: "social-psychology", parent: psychology)
Category.create!(name: "Developmental Psychology", slug: "developmental-psychology", parent: psychology)

# Art
art = Category.create!(name: "Art", slug: "art")
Category.create!(name: "Visual Arts", slug: "visual-arts", parent: art)
Category.create!(name: "Music Theory", slug: "music-theory", parent: art)
Category.create!(name: "Design Theory", slug: "design-theory", parent: art)
Category.create!(name: "Narratology", slug: "narratology", parent: art)
Category.create!(name: "Art History", slug: "art-history", parent: art)
Category.create!(name: "Performance Arts", slug: "performance-arts", parent: art)
Category.create!(name: "Aesthetics", slug: "aesthetics", parent: art)

# Systems Theory (interdisciplinary field)
systems_theory = Category.create!(name: "Systems Theory", slug: "systems-theory")
Category.create!(name: "Complex Systems", slug: "complex-systems", parent: systems_theory)
Category.create!(name: "Network Theory", slug: "network-theory", parent: systems_theory)
Category.create!(name: "Information Architecture", slug: "information-architecture", parent: systems_theory)

# Linguistics
linguistics = Category.create!(name: "Linguistics", slug: "linguistics")
Category.create!(name: "Semantics", slug: "semantics", parent: linguistics)
Category.create!(name: "Pragmatics", slug: "pragmatics", parent: linguistics)
Category.create!(name: "Sociolinguistics", slug: "sociolinguistics", parent: linguistics)

# Anthropology
anthropology = Category.create!(name: "Anthropology", slug: "anthropology")
Category.create!(name: "Cultural Anthropology", slug: "cultural-anthropology", parent: anthropology)
Category.create!(name: "Social Anthropology", slug: "social-anthropology", parent: anthropology)

puts "Created #{Category.count} categories"
