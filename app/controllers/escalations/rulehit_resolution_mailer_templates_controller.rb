class Escalations::RulehitResolutionMailerTemplatesController < ApplicationController
  before_action :set_rulehit_resolution_mailer_template, only: [:show, :edit, :update, :destroy]
  layout "escalations/webrep/disputes"

  # GET /rulehit_resolution_mailer_templates
  # GET /rulehit_resolution_mailer_templates.json
  def index
    @rulehit_resolution_mailer_templates = RulehitResolutionMailerTemplate.all
  end

  # GET /rulehit_resolution_mailer_templates/1
  # GET /rulehit_resolution_mailer_templates/1.json
  def show
  end

  # GET /rulehit_resolution_mailer_templates/new
  def new
    @rulehit_resolution_mailer_template = RulehitResolutionMailerTemplate.new
  end

  # GET /rulehit_resolution_mailer_templates/1/edit
  def edit
  end

  # POST /rulehit_resolution_mailer_templates
  # POST /rulehit_resolution_mailer_templates.json
  def create
    @rulehit_resolution_mailer_template = RulehitResolutionMailerTemplate.new(rulehit_resolution_mailer_template_params)

    respond_to do |format|
      if @rulehit_resolution_mailer_template.save
        format.html { redirect_to escalations_rulehit_resolution_mailer_template_url(@rulehit_resolution_mailer_template), notice: 'Rulehit resolution mailer template was successfully created.' }
        format.json { render :show, status: :created, location: @rulehit_resolution_mailer_template }
      else
        format.html { render :new }
        format.json { render json: @rulehit_resolution_mailer_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rulehit_resolution_mailer_templates/1
  # PATCH/PUT /rulehit_resolution_mailer_templates/1.json
  def update
    respond_to do |format|
      if @rulehit_resolution_mailer_template.update(rulehit_resolution_mailer_template_params)
        format.html { redirect_to escalations_rulehit_resolution_mailer_template_url(@rulehit_resolution_mailer_template), notice: 'Rulehit resolution mailer template was successfully updated.' }
        format.json { render :show, status: :ok, location: @rulehit_resolution_mailer_template }
      else
        format.html { render :edit }
        format.json { render json: @rulehit_resolution_mailer_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rulehit_resolution_mailer_templates/1
  # DELETE /rulehit_resolution_mailer_templates/1.json
  def destroy
    @rulehit_resolution_mailer_template.destroy
    respond_to do |format|
      format.html { redirect_to escalations_rulehit_resolution_mailer_templates_url, notice: 'Rulehit resolution mailer template was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_rulehit_resolution_mailer_template
      @rulehit_resolution_mailer_template = RulehitResolutionMailerTemplate.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def rulehit_resolution_mailer_template_params
      params.require(:rulehit_resolution_mailer_template).permit(:mnemonic, :to, :cc, :subject, :body)
    end
end
