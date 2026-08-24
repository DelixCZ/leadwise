require "test_helper"
require "faraday"
require "faraday/adapter/test"

class GeminiScorerServiceTest < ActiveSupport::TestCase
  setup do
    @lead = Lead.new(company_name: "Acme Corp", website: "https://www.acme.example")
  end

  test "uses mock evaluation when API key is missing" do
    result = GeminiScorerService.call(@lead, api_key: "", seller_description: "Warehouse automation for logistics firms")

    assert_includes 60..95, result[:score]
    assert_equal 3, result[:analysis].lines.count
    assert_match(/Acme Corp/, result[:analysis])
    assert_match(/would be unlikely to buy|switching cost|not treat this as an urgent/i, result[:objection])
    assert_equal :mock, result[:source]
    assert_match(/Warehouse automation/, result[:prompt])
    assert_match(/interested in the seller/, result[:prompt])
    assert_equal "Warehouse automation for logistics firms", result[:seller_profile]
  end

  test "parses a live Gemini JSON payload" do
    payload = {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              { "text" => { score: 91, analysis: "• Strong brand.\n• Clear budget.\n• Fast close.", objection: "They may already have an in-house CRM." }.to_json }
            ]
          }
        }
      ]
    }

    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get("/v1beta/models") do
      [
        200,
        { "Content-Type" => "application/json" },
        { models: [ { name: "models/gemini-2.5-flash", supportedGenerationMethods: [ "generateContent" ] } ] }.to_json
      ]
    end
    stubs.post("/v1beta/models/gemini-2.5-flash:generateContent") do
      [ 200, { "Content-Type" => "application/json" }, payload.to_json ]
    end

    client = Faraday.new(url: GeminiScorerService::API_HOST) do |faraday|
      faraday.request :json
      faraday.response :json, content_type: /\bjson$/
      faraday.adapter :test, stubs
    end

    result = GeminiScorerService.call(@lead, client: client, api_key: "test-key")

    assert_equal 91, result[:score]
    assert_match(/Strong brand/, result[:analysis])
    assert_match(/in-house CRM/, result[:objection])
    assert_equal :live, result[:source]
    stubs.verify_stubbed_calls
  end

  test "returns a fallback result when the live API errors" do
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get("/v1beta/models") do
      [ 200, { "Content-Type" => "application/json" }, { models: [] }.to_json ]
    end
    GeminiScorerService::MODEL_PATHS.each do |path|
      stubs.post(path) do
        [ 500, { "Content-Type" => "application/json" }, { error: "boom" }.to_json ]
      end
    end

    client = Faraday.new(url: GeminiScorerService::API_HOST) do |faraday|
      faraday.request :json
      faraday.response :json, content_type: /\bjson$/
      faraday.response :raise_error
      faraday.adapter :test, stubs
    end

    result = GeminiScorerService.call(@lead, client: client, api_key: "test-key")

    assert_equal 65, result[:score]
    assert_match(/unavailable/i, result[:analysis])
    assert_match(/could not be fully evaluated/i, result[:objection])
    assert_equal :fallback, result[:source]
  end
end
