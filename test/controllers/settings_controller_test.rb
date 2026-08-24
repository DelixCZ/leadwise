require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test "updates company description" do
    patch setting_url, params: { setting: { company_description: "We sell CRM software to exporters." } }

    assert_redirected_to root_url
    assert_equal "We sell CRM software to exporters.", Setting.current.company_description
  end
end
