# frozen_string_literal: true

class GeminiScorerService
  API_HOST = "https://generativelanguage.googleapis.com"
  MODEL_PATHS = [
    "/v1beta/models/gemini-flash-latest:generateContent",
    "/v1beta/models/gemini-2.0-flash:generateContent",
    "/v1beta/models/gemini-2.0-flash-001:generateContent",
    "/v1beta/models/gemini-1.5-flash:generateContent",
    "/v1beta/models/gemini-2.5-flash:generateContent"
  ].freeze

  def self.call(lead, **kwargs)
    new(lead, **kwargs).call
  end

  def initialize(lead, client: nil, api_key: ENV["GEMINI_API_KEY"], seller_description: nil)
    @lead = lead
    @client = client
    @api_key = api_key.to_s.strip
    @seller_description = seller_description.to_s.strip
  end

  def call
    result = @api_key.present? ? live_evaluate : mock_evaluate
    normalize(result).merge(
      source: result[:source] || :live,
      prompt: evaluation_prompt,
      seller_profile: @seller_description
    )
  rescue StandardError => e
    Rails.logger.warn("[GeminiScorerService] #{e.class}: #{sanitize_error(e.message)}")
    fallback_result
  end

  def evaluation_prompt
    [system_instruction, user_prompt].join("\n\n")
  end

  private

  def mock_evaluate
    simulate_latency
    score = rand(60..95)
    { score: score, analysis: mock_analysis(score), objection: mock_objection(score), source: :mock }
  end

  def live_evaluate
    last_error = nil

    candidate_paths.each do |path|
      response = post_generate(path)
      parsed = parse_model_response(response.body)
      Rails.logger.info("[GeminiScorerService] scored via #{path}")
      return parsed.merge(source: :live)
    rescue Faraday::Error => e
      last_error = e
      Rails.logger.warn("[GeminiScorerService] #{path} failed: #{e.class} #{e.response&.dig(:status)}")
    end

    raise last_error if last_error
  end

  def candidate_paths
    (discovered_model_paths + MODEL_PATHS).uniq
  end

  def discovered_model_paths
    response = connection.get("/v1beta/models") do |req|
      req.headers["x-goog-api-key"] = @api_key
    end
    payload = response.body.is_a?(String) ? JSON.parse(response.body) : response.body
    Array(payload && payload["models"]).filter_map do |model|
      methods = Array(model["supportedGenerationMethods"])
      next if methods.any? && methods.exclude?("generateContent")

      id = model["name"].to_s.sub(/\Amodels\//, "")
      next unless id.match?(/flash/i)

      "/v1beta/models/#{id}:generateContent"
    end
  rescue StandardError
    []
  end

  def post_generate(path)
    attempts = 0
    begin
      attempts += 1
      connection.post(path) do |req|
        req.headers["x-goog-api-key"] = @api_key
        req.body = request_payload
      end
    rescue Faraday::ServerError
      raise if attempts >= 3 || Rails.env.test?

      sleep(attempts)
      retry
    end
  end

  def connection
    @client ||= Faraday.new(url: API_HOST) do |faraday|
      faraday.request :json
      faraday.response :json, content_type: /\bjson$/
      faraday.response :raise_error
      faraday.options.timeout = 20
      faraday.options.open_timeout = 5
      faraday.adapter Faraday.default_adapter
    end
  end

  def request_payload
    {
      system_instruction: {
        parts: [ { text: system_instruction } ]
      },
      contents: [
        {
          role: "user",
          parts: [ { text: user_prompt } ]
        }
      ],
      generationConfig: {
        temperature: 0.2,
        responseMimeType: "application/json",
        responseSchema: {
          type: "OBJECT",
          properties: {
            score: { type: "INTEGER" },
            analysis: { type: "STRING" },
            objection: { type: "STRING" }
          },
          required: %w[score analysis objection]
        }
      }
    }
  end

  def system_instruction
    <<~TEXT
      You are a B2B sales analyst. Compare a prospect company to the seller's products and services.
      Return only JSON with keys "score" (integer 1-100), "analysis", and "objection".
      "analysis" must be exactly 3 bullet points, each on its own line, starting with •.
      Never put multiple bullets on one line. Wrap naturally; do not output a single long line.
      "objection" must be one short sentence explaining why this company would most likely not buy from the seller
      or not use the seller's services, even if the fit score is high.
      The score is how likely this prospect would be interested in buying from the seller.
      Higher scores mean a stronger product-market fit, clearer need, and better chance they would take a sales conversation.
    TEXT
  end

  def user_prompt
    seller = @seller_description.present? ? @seller_description : "Not provided. Infer a generic B2B offering and say the seller profile is missing."

    <<~PROMPT
      Decide whether this prospect would be interested in the seller's products or services.

      Seller (our company — products and services we sell):
      #{seller}

      Prospect to evaluate:
      Company name: #{@lead.company_name}
      Website: #{@lead.website}

      Score 1-100 using:
      - How well the prospect's business could use the seller's products/services
      - Likely budget and ability to buy
      - Industry / use-case overlap with the seller
      - Likelihood they would take a sales conversation

      In the 3 bullets, explain the fit (or lack of fit) against the seller's offering.
      Put each bullet on its own line.
      Also give one short sentence for "objection": the most likely reason they would not buy or use the seller's services.
      Respond with JSON: {"score": <1-100 integer>, "analysis": "<3 bullet points, each on its own line>", "objection": "<one short sentence>"}.
    PROMPT
  end

  def parse_model_response(body)
    payload = extract_json(body)
    {
      score: payload["score"],
      analysis: coerce_analysis(payload["analysis"]),
      objection: coerce_objection(payload["objection"])
    }
  end

  def extract_json(body)
    parsed_body = body.is_a?(String) ? JSON.parse(body) : body
    text = parsed_body.dig("candidates", 0, "content", "parts", 0, "text")
    raise JSON::ParserError, "Gemini response did not include text" if text.blank?

    json_text = text.to_s.strip
      .sub(/\A```(?:json)?\s*/i, "")
      .sub(/```\z/, "")
      .strip

    JSON.parse(json_text)
  end

  def coerce_analysis(value)
    lines =
      case value
      when Array
        value
      else
        value.to_s.split(/\n+|(?<=\S)\s*•\s*/)
      end

    lines.map { |line| format_bullet(line) }.reject(&:blank?).join("\n")
  end

  def coerce_objection(value)
    value.to_s.sub(/\A[•\-*]\s*/, "").gsub(/\s+/, " ").strip
  end

  def format_bullet(line)
    text = line.to_s.sub(/\A[•\-*]\s*/, "").strip
    text.present? ? "• #{text}" : ""
  end

  def normalize(result)
    hash = result.respond_to?(:to_h) ? result.to_h : result
    score = Integer(hash[:score] || hash["score"])
    raise ArgumentError, "score out of range" unless (1..100).cover?(score)

    analysis = hash[:analysis] || hash["analysis"]
    raise ArgumentError, "analysis missing" if analysis.blank?

    objection = coerce_objection(hash[:objection] || hash["objection"])
    objection = "A likely blocker was not identified." if objection.blank?

    { score: score, analysis: analysis.to_s, objection: objection }
  end

  def mock_analysis(score)
    company = @lead.company_name.presence || "This company"
    website = @lead.website.presence || "their website"
    fit =
      if score >= 85
        "a high-priority outbound target with likely budget and a short sales cycle"
      elsif score >= 70
        "a solid mid-to-high fit account worth a tailored sequence"
      else
        "a qualified but not urgent opportunity pending clearer buying signals"
      end

    seller_clause = @seller_description.present? ? "the seller's described offering" : "a typical B2B offering (no seller profile was provided)"

    <<~TEXT.strip
      • #{company} looks like #{fit} for #{seller_clause}, based on public positioning at #{website}.
      • Overlap between their likely operations and what the seller sells appears #{score >= 70 ? "meaningful" : "limited"}, so outreach should be #{score >= 70 ? "prioritized" : "cautious"}.
      • Recommended next step: confirm a concrete use case in their stack before a full sales sequence.
    TEXT
  end

  def mock_objection(score)
    company = @lead.company_name.presence || "This company"
    if score >= 85
      "#{company} may already run an incumbent tool, so switching cost could still block a purchase."
    elsif score >= 70
      "#{company} may not treat this as an urgent priority versus other operational investments."
    else
      "#{company} may sit outside the seller's ideal customer profile, so they would be unlikely to buy."
    end
  end

  def fallback_result
    company = @lead.company_name.presence || "This company"
    website = @lead.website.presence || "the company website"

    {
      score: 65,
      analysis: <<~TEXT.strip,
        • Live AI evaluation was unavailable, so #{company} received a conservative baseline score.
        • Review #{website} against your company profile for product-fit, budget, and whether they would need your services.
        • Re-run scoring when the Gemini API is reachable to replace this placeholder analysis.
      TEXT
      objection: "#{company} could not be fully evaluated, so they may not need the seller's services.",
      source: :fallback,
      prompt: evaluation_prompt,
      seller_profile: @seller_description
    }
  end

  def simulate_latency
    sleep(1) unless Rails.env.test?
  end

  def sanitize_error(message)
    message.to_s.gsub(/key=[^&\s]+/i, "key=[FILTERED]").gsub(/AQ\.[A-Za-z0-9_-]+/, "[FILTERED]")
  end
end
