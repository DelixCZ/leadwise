require "test_helper"

class LeadTest < ActiveSupport::TestCase
  test "valid with required fields" do
    lead = Lead.new(company_name: "Acme", website: "https://acme.example")
    assert lead.valid?
  end

  test "requires company name and website" do
    lead = Lead.new
    assert_not lead.valid?
    assert_includes lead.errors[:company_name], "can't be blank"
    assert_includes lead.errors[:website], "can't be blank"
  end

  test "allows nil ai_score" do
    lead = Lead.new(company_name: "Acme", website: "https://acme.example", ai_score: nil)
    assert lead.valid?
  end

  test "ai_score must be between 1 and 100" do
    lead = Lead.new(company_name: "Acme", website: "https://acme.example", ai_score: 0)
    assert_not lead.valid?

    lead.ai_score = 101
    assert_not lead.valid?

    lead.ai_score = 50
    assert lead.valid?
  end

  test "analysis_bullets splits bullet text" do
    lead = Lead.new(ai_analysis: "• First point.\n• Second point.")
    assert_equal [ "First point.", "Second point." ], lead.analysis_bullets
  end

  test "analysis_bullets splits bullets jammed onto one line" do
    lead = Lead.new(ai_analysis: "• First point. • Second point. • Third point.")
    assert_equal [ "First point.", "Second point.", "Third point." ], lead.analysis_bullets
  end

  test "company_profile_snapshot returns stored seller text" do
    lead = Lead.new(evaluation_prompt: "We sell warehouse automation to logistics firms.")
    assert_equal "We sell warehouse automation to logistics firms.", lead.company_profile_snapshot
  end

  test "company_profile_snapshot extracts seller text from a full Gemini prompt" do
    lead = Lead.new(evaluation_prompt: <<~PROMPT)
      You are a B2B sales analyst. Compare a prospect company to the seller's products and services.

      Seller (our company — products and services we sell):
      We sell warehouse automation.

      Prospect to evaluate:
      Company name: Acme
    PROMPT

    assert_equal "We sell warehouse automation.", lead.company_profile_snapshot
  end
end
