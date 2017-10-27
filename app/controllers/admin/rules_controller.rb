class Admin::RulesController < Admin::HomeController

  def index
    @rules = Rule.left_joins(:bugs).group(:id).select("count(*) as bug_count, rules.*")
  end

  def edit
    @rule = Rule.find(params[:id])
  end

  def update
    @rule = Rule.find(params[:id])
    @rule.update(rule_params)
    if @rule.save
      flash[:notice] = "#{@rule.sid} updated successfully."
    else
      flash[:alert] = "Unable to update #{@rule.sid}."
    end
    redirect_to admin_rules_path
  end

  private

  def rule_params
    params.require(:rule).permit(:state, :edit_status, :publish_status)
  end
end