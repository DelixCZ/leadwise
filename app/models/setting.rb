class Setting < ApplicationRecord
  def self.current
    order(:id).first_or_create!
  end

  def profile_present?
    company_description.to_s.strip.present?
  end
end
