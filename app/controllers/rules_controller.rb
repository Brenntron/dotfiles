class RulesController < ApplicationController

  def create
    @bug = Bug.find(params[:rule][:bug_id])
    @rule = Rule.new(rules_params)

    [:connection, :flow, :metadata].each do |data|
      @rule[data] = params[:rule][data].join(" ") if params[:rule][data].is_a? Array
    end
    if @rule.save
      @bug.rules << @rule
      @rule.create_references(params[:rule][:reference]) if params[:rule][:reference]
      redirect_to bug_path(params[:rule][:bug_id])
    end
  end

  def update
    new_rule = Rule.create(Rule.parse_and_create_rule(params[:rule][:rule_content]))
    new_rule.update(publish_status: Rule::PUBLISH_STATUS_NEW) unless new_rule.sid
    new_rule.bugs << Bug.where(id: params[:rule][:bug_id]).first if params[:rule][:bug_id]
    new_rule.associate_references(params[:rule][:rule_content])
    new_rule.update(detection: params[:rule][:detection].strip!, class_type: params[:rule][:class_type]) if new_rule.state == 'FAILED'
    render json: new_rule
  end

  def destroy
    if params[:ids]
      params[:ids].each do |id|
        rule = Rule.find_by id: id
        rule.destroy if rule
      end
    end
    render json: {success: 'Rule has been deleted'}, status: 200
  end

  def get_impact
    classification = params[:classification]
    respond_to do |format|
      format.js {
        render :js => RulesHelper::CLASSIFICATION[classification]
      }
    end
  end


  private

  def rules_params
    params.require(:rule).permit(:message, :connection, :flow, :detection, :metadata, :class_type, :rule_category_id)
  end

end