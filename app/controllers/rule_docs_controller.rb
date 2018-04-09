class RuleDocsController < ApplicationController
  load_and_authorize_resource

  def index
    respond_to do |format|
      format.html
      format.json { render json: RuleDocDatatable.new(view_context) }
    end
  end
  def new
    @rule_doc = RuleDoc.new
  end
  def create
    rule = Rule.where(gid:rule_params[:gid]).where(sid:rule_params[:sid]).first
    @rule_doc = RuleDoc.new(rule_doc_params)
    @rule_doc.rule_id = rule.id
    respond_to do |format|
      if @rule_doc.save
        format.html { redirect_to rule_docs_path, notice: 'Rule document was successfully created.' }
      else
        format.html {
          flash[:error]=  @rule_doc.errors.full_messages.to_sentence
          render :new }
      end
    end
  end
  def edit
    @rule_doc = RuleDoc.find(params[:id])
  end
  def show
    @rule_doc = RuleDoc.find(params[:id])
  end
  def update
    @rule_doc = RuleDoc.find(params[:id])
    @rule_doc.update(rule_doc_params)
    if @rule_doc.save
      flash[:notice] = "#{@rule_doc.sid} updated successfully."
    else
      flash[:alert] = "Unable to update #{@rule_doc.sid}."
    end
    redirect_to rule_docs_path
  end

  def destroy
    @rule_doc.destroy
    respond_to do |format|
      format.html { redirect_to rule_docs_url, notice: 'rule document was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def rule_params
    params.require(:rule_doc).permit(:sid,:gid)
  end
  def rule_doc_params
    params.require(:rule_doc).permit(:id, :summary, :details, :rule_id, :impact, :affected_sys, :false_positives, :false_negatives, :contributors, :policies, :is_community)
  end
end