class Admin::OrgSubsetsController < Admin::HomeController

  # GET /roles
  # GET /org_subsets.json
  def index
    @org_subsets = OrgSubset.all
  end

  # GET /org_subsets/new
  def new
    @org_subset = OrgSubset.new
  end

  # GET /org_subsets/1/edit
  def edit
    @org_subset = OrgSubset.find(params[:id])
  end

  # POST /org_subsets
  # POST /org_subsets.json
  def create
    @org_subset = OrgSubset.new(org_subset_params)
    respond_to do |format|
      if @org_subset.save
        format.html {redirect_to admin_org_subsets_path, notice: 'org_subset was successfully created.'}
      else
        format.html {render :new}
      end
    end
  end

  # PATCH/PUT /org_subsets/1
  # PATCH/PUT /org_subsets/1.json
  def update
    @org_subset = OrgSubset.find(params[:id])
    respond_to do |format|
      if @org_subset.update(org_subset_params)
        format.html {redirect_to admin_org_subsets_path, notice: 'org_subset was successfully updated.'}
      else
        format.html {render :edit}
      end
    end
  end

  # DELETE /org_subsets/1
  # DELETE /org_subsets/1.json
  def destroy
    @org_subset = OrgSubset.find(params[:id])
    @org_subset.destroy
    respond_to do |format|
      format.html {redirect_to admin_org_subsets_url, notice: 'org_subset was successfully destroyed.'}
      format.json {head :no_content}
    end
  end

  private
  # Never trust parameters from the scary internet, only allow the white list through.
  def org_subset_params
    params.require(:org_subset).permit(:name)
  end

end

