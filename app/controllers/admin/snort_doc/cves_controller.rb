require 'snort_doc_publisher'

class Admin::SnortDoc::CvesController < ApplicationController
  layout 'admin/snort_doc/root'

  def index
  end

  def nvd
  end

  def download
    SnortDocPublisher.download(download_params['filename'])

    redirect_to admin_snort_doc_cves_nvd_path
  end

  private

  def download_params
    params.permit(:filename)
  end
end
