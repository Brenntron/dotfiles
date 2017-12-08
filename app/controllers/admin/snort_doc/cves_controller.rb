require 'snort_doc_publisher'

class Admin::SnortDoc::CvesController < ApplicationController
  layout 'admin/snort_doc/root'

  def nvd
  end

  def download
    SnortDocPublisher.download(download_params['filename'])

    redirect_to admin_snort_doc_cves_nvd_path
  end

  def missing
    @missing_references = Reference.cves.left_joins(:cve).where(cves: {id: nil}).order(:reference_data)
  end

  def update
    SnortDocPublisher.update_cve_data

    redirect_to admin_snort_doc_cves_missing_path
  end

  private

  def download_params
    params.permit(:filename)
  end
end
