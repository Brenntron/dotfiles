class Escalations::FileRep::DisputesController < ApplicationController

  def index
    @conventions = AmpNamingConvention.order(:table_sequence).all

    respond_to do |format|
      format.html {  }
      format.json do
        render json: FileRepDatatable.new(params,
                                          initialize_params,
                                          user: current_user)
      end
      format.xlsx do
        workbook = FileReputationDispute.export_xlsx(params['data_json'], current_user: current_user)
        send_data workbook.stream.string, filename: "filerep_search_#{Time.now}.xlsx", disposition: 'attachment'
      end
    end
  end

  def show
    @file_rep_dispute = FileReputationDispute.find(params[:id])
    @versioned_items = @file_rep_dispute.compose_versioned_items
    @conventions = AmpNamingConvention.order(:table_sequence).all
  end

  def sandbox_html_report
    api_response = FileReputationApi::Sandbox.full_report_html(params['sha256_hash'], params['run_id'])

    if api_response[:data].present?
      file_contents = api_response[:data].body.force_encoding("ISO-8859-1").encode("UTF-8")
    else
      file_contents = "No Sandbox report found."
    end

    respond_to do |format|

      format.html { render body: file_contents }
      format.gzip do
        # Note: When I started this, I thought I would have to gzip this in order
        # for it to download properly. Turns out, that is not true. We can send the
        # HTML file directly, so that's what we do. If anyone complains, we can
        # zip it later, but for now, I don't see any reason to add an extra step
        # for the end users.
        send_data file_contents, :filename => "sandbox-report_#{Time.now}.html"
      end
    end
  end

  def naming_guide
    # Sort records by table sequence
    @conventions = AmpNamingConvention.order(:table_sequence).all
  end


  private

  def datatables_search_params
    params.require(:search).permit(:value)
  end

  def robust_search_params
    params.permit(:search, :search_type, :search_name)
  end

  def search_conditions
    params.has_key?('search_conditions') ? params.require('search_conditions').permit! : nil
  end

  def initialize_params
    robust_search_params.merge(datatables_search_params).merge('search_conditions' => search_conditions)
  end

end
