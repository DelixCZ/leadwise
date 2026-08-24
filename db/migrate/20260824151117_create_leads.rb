class CreateLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :leads do |t|
      t.string :company_name, null: false
      t.string :website, null: false
      t.integer :ai_score
      t.text :ai_analysis

      t.timestamps
    end

    add_check_constraint :leads,
      "ai_score IS NULL OR (ai_score BETWEEN 1 AND 100)",
      name: "leads_ai_score_range"
  end
end
