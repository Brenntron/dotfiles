class Escalations::FileRep::DisputesController < ApplicationController

  def index
    respond_to do |format|
      format.html {  }
      format.json do
        render json: FileRepDatatable.new(params,
                                          search_params.merge('search_conditions' => search_conditions),
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

  end


  private

  def search_params
    params.permit(:search_type, :search_name)
  end

  def search_conditions
    params.has_key?('search_conditions') ? params.require('search_conditions').permit! : nil
  end
end
