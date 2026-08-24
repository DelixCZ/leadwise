class AddSellerProfileAndEvaluationPrompt < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.text :company_description

      t.timestamps
    end

    add_column :leads, :evaluation_prompt, :text
  end
end
