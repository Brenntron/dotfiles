class RuleDocsController < ApplicationController
  layout 'admin'
  before_action { authorize!(:manage, Admin) }
  load_and_authorize_resource

  def index
    respond_to do |format|
      format.html
      format.json { render json: RuleDocDatatable.new(view_context) }
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

  def validations
    @invalid_rule_docs = RuleDoc.order("updated_at desc").all.to_a.reject{ |doc| doc.valid? }
  end

  def destroy
    @rule_doc.destroy
    respond_to do |format|
      format.html { redirect_to rule_docs__url, notice: 'rule document was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def rule_doc_params
    params.require(:rule_doc).permit(:id, :summary, :details, :sid)
  end
end