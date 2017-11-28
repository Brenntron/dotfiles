class Admin::RulesController < Admin::HomeController

  def index
    respond_to do |format|
      format.html
      format.json { render json: RuleDatatable.new(view_context) }
    end
    @invalid_rules = Rule.order("updated_at desc").all.to_a.reject{ |rule| rule.valid? }
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

  def validations
    @invalid_rules = Rule.order("updated_at desc").all.to_a.reject{ |rule| rule.valid? }
  end

  def related
    @rule = Rule.where(id: params[:id]).first || Rule.new
  end

  private

  def rule_params
    params.require(:rule).permit(:state, :edit_status, :publish_status, :sid)
  end
end
