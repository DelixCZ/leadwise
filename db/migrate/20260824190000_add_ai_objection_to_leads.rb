class AddAiObjectionToLeads < ActiveRecord::Migration[8.1]
  def change
    add_column :leads, :ai_objection, :text
  end
end
