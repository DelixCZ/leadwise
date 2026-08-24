class SettingsController < ApplicationController
  def update
    @setting = Setting.current

    if @setting.update(setting_params)
      redirect_to root_path, notice: "Your company profile was saved. New AI evaluations will use it."
    else
      redirect_to root_path, alert: "Could not save your company profile."
    end
  end

  private

  def setting_params
    params.require(:setting).permit(:company_description)
  end
end
