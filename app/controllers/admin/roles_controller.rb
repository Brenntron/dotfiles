class Admin::RolesController < Admin::HomeController
  load_and_authorize_resource class: 'Role'

  # GET /roles
  # GET /roles.json
  def index
    @roles = Role.all
  end
  
  # GET /roles/new
  def new
    @role = Role.new
  end

  # GET /roles/1/edit
  def edit
    @role = Role.find(params[:id])
  end

  # POST /roles
  # POST /roles.json
  def create
    @role = Role.new(role_params)
    respond_to do |format|
      if @role.save
        format.html { redirect_to admin_roles_path, notice: 'role was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /roles/1
  # PATCH/PUT /roles/1.json
  def update
    @role = Role.find(params[:id])
    respond_to do |format|
      if @role.update(role_params)
        format.html { redirect_to admin_roles_path, notice: 'role was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /roles/1
  # DELETE /roles/1.json
  def destroy
    @role = Role.find(params[:id])
    @role.destroy
    respond_to do |format|
      format.html { redirect_to roles_url, notice: 'role was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Never trust parameters from the scary internet, only allow the white list through.
  def role_params
    params.require(:role).permit(:role, :org_subset_id)
  end

end
