class LeadsController < ApplicationController
  before_action :set_lead, only: %i[show destroy re_score]

  def index
    @leads = Lead.order(created_at: :desc)
    @setting = Setting.current
    @open_lead_id = params[:open].presence&.to_i
  end

  def show
  end

  def new
    @lead = Lead.new
  end

  def create
    @lead = Lead.new(lead_params)

    if @lead.save
      source = apply_ai_score(@lead)
      redirect_to leads_path(open: @lead.id), notice: score_notice(source, verb: "created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @lead.destroy
    redirect_to leads_path, notice: "Lead was successfully deleted.", status: :see_other
  end

  def re_score
    source = apply_ai_score(@lead)
    redirect_to leads_path(open: @lead.id), notice: score_notice(source, verb: "re-evaluated")
  end

  private

  def set_lead
    @lead = Lead.find(params[:id])
  end

  def lead_params
    params.require(:lead).permit(:company_name, :website)
  end

  def apply_ai_score(lead)
    result = GeminiScorerService.call(lead, seller_description: Setting.current.company_description)
    lead.update!(
      ai_score: result[:score],
      ai_analysis: result[:analysis],
      ai_objection: result[:objection],
      evaluation_prompt: result[:seller_profile]
    )
    result[:source]
  rescue StandardError => e
    Rails.logger.warn("[LeadsController] AI scoring failed for lead #{lead.id}: #{e.message}")
    flash[:alert] = "The lead was saved, but AI scoring could not be completed."
    :fallback
  end

  def score_notice(source, verb:)
    case source
    when :live
      "Lead was #{verb} with Gemini."
    when :mock
      "Lead was #{verb} with mock scoring (GEMINI_API_KEY is not set)."
    else
      "Lead was #{verb}, but Gemini returned an error so a fallback score was used. Check the Rails server log."
    end
  end
end
