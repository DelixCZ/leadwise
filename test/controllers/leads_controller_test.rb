require "test_helper"

class LeadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lead = Lead.create!(
      company_name: "Test Co",
      website: "https://test.example",
      ai_score: 72,
      ai_analysis: "• Solid mid-market fit.\n• Clear website presence.\n• Moderate buying signals."
    )
  end

  test "should get index" do
    get leads_url
    assert_response :success
    assert_match @lead.company_name, @response.body
    assert_no_match "Add lead", @response.body
    assert_match "Your company", @response.body
  end

  test "new lead form includes a working-state overlay" do
    get new_lead_url
    assert_response :success
    assert_match "loading-form", @response.body
    assert_match "Scoring this lead with AI", @response.body
    assert_match "Create lead", @response.body
  end

  test "should create lead and persist AI score" do
    Setting.current.update!(company_description: "We sell warehouse software to logistics firms.")

    assert_difference("Lead.count", 1) do
      post leads_url, params: { lead: { company_name: "New Co", website: "https://new.example" } }
    end

    lead = Lead.last
    assert_redirected_to leads_url(open: lead.id)
    assert_includes 60..95, lead.ai_score
    assert_equal 3, lead.analysis_bullets.size
    assert_equal "We sell warehouse software to logistics firms.", lead.evaluation_prompt
    assert lead.ai_objection.present?
  end

  test "should not create invalid lead" do
    assert_no_difference("Lead.count") do
      post leads_url, params: { lead: { company_name: "", website: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "should show lead" do
    get lead_url(@lead)
    assert_response :success
    assert_match @lead.company_name, @response.body
    assert_match "Re-evaluate with AI", @response.body
    assert_match "Show prompt", @response.body
  end

  test "should re-score lead" do
    post re_score_lead_url(@lead)

    assert_redirected_to leads_url(open: @lead.id)
    @lead.reload
    assert_includes 60..95, @lead.ai_score
    assert_equal 3, @lead.analysis_bullets.size
    assert @lead.ai_objection.present?
  end

  test "should destroy lead" do
    assert_difference("Lead.count", -1) do
      delete lead_url(@lead)
    end

    assert_redirected_to leads_url
  end
end
