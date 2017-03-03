class ReferencesController < ApplicationController
  load_and_authorize_resource

  def create
    @bug = Bug.find(params[:bug_id])
    @reference = @bug.references.build(reference_params)
    if @reference.save
      render json: @reference
    else
      render json: {}
    end
  end

  private

  def reference_params
    params.require(:reference).permit(:reference_type_id, :reference_data)
  end

end