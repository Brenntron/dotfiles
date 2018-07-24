class Admin::ReferenceTypesController < Admin::HomeController
  load_and_authorize_resource class: 'ReferenceType'

  def index
    @ref_types = ReferenceType.all
  end
  def edit
    @ref_type = ReferenceType.find(params[:id])
  end

  def update
    @ref_type = ReferenceType.find(params[:id])
    @ref_type.update(reference_type_params)
    if @ref_type.save
      flash[:notice] = "Reference type updated successfully."
    else
      flash[:alert] = "Unable to update reference type."
    end
    redirect_to admin_reference_types_path
  end

  private

  def reference_type_params
    params.require(:reference_type).permit(:name,:description,:validation,:bugzilla_format,:example,:rule_format,:url)
  end
end
