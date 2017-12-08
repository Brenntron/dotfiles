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
    @missing_count = @missing_references.count
    @missing_limit = 500
  end

  def update
    error_limit = 30

    SnortDocPublisher.update_cve_data
    if SnortDocPublisher.errors.empty?
      flash[:info] += "No errors"
    else
      SnortDocPublisher.errors.each { |msg| Rails.logger.error(msg) }
      flash[:error] = SnortDocPublisher.errors[0..error_limit].join("\n")
      if error_limit < SnortDocPublisher.errors.count
        flash[:error] += "\n... first #{error_limit}"
      end
    end

    redirect_to admin_snort_doc_cves_missing_path
  end

  private

  def download_params
    params.permit(:filename)
  end
end
