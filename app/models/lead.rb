class Lead < ApplicationRecord
  validates :company_name, presence: true
  validates :website, presence: true
  validates :ai_score,
    numericality: { only_integer: true, in: 1..100 },
    allow_nil: true

  def analysis_bullets
    return [] if ai_analysis.blank?

    ai_analysis.to_s
      .split(/\n+|(?<=\S)\s*•\s*/)
      .map { |line| line.sub(/\A[•\-*]\s*/, "").strip }
      .reject(&:blank?)
  end

  def company_profile_snapshot
    stored = evaluation_prompt.to_s.strip
    return stored unless stored.present? && looks_like_full_prompt?(stored)

    extract_seller_from_prompt(stored).presence || stored
  end

  def pending_evaluation?
    ai_score.nil?
  end

  private

  def looks_like_full_prompt?(text)
    text.include?("You are a B2B sales analyst") || text.include?("Prospect to evaluate:")
  end

  def extract_seller_from_prompt(text)
    match = text.match(/Seller \(our company[^\n]*:\n(.+?)\n\nProspect to evaluate:/m)
    match && match[1].to_s.strip
  end
end
