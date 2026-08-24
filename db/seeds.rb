leads = [
  {
    company_name: "Stripe",
    website: "https://stripe.com",
    ai_score: 94,
    ai_analysis: <<~TEXT.strip
      • Global payments leader with a large, growing TAM in B2B financial infrastructure.
      • Strong product-led growth, developer adoption, and enterprise expansion motion.
      • High intent fit for premium CRM outreach given budget, tech sophistication, and buying velocity.
    TEXT
  },
  {
    company_name: "Shopify",
    website: "https://www.shopify.com",
    ai_score: 88,
    ai_analysis: <<~TEXT.strip
      • Dominant commerce platform with millions of merchants and expanding B2B/Plus offerings.
      • Clear need for sales tooling around partnerships, Plus-tier accounts, and ecosystem apps.
      • Strong brand, healthy cash position, and consistent investment in go-to-market teams.
    TEXT
  },
  {
    company_name: "Acme Corp",
    website: "https://www.acme.example",
    ai_score: 61,
    ai_analysis: <<~TEXT.strip
      • Mid-market manufacturer with a public website but limited digital sales presence.
      • Potential fit if they are actively hiring sales ops or rolling out a CRM modernization.
      • Score is moderate due to unclear budget signals and limited publicly available buying intent.
    TEXT
  }
]

leads.each do |attrs|
  Lead.find_or_create_by!(company_name: attrs[:company_name]) do |lead|
    lead.assign_attributes(attrs)
  end
end
