class ComplaintEntry < ApplicationRecord
  belongs_to :complaint

  def location_url
    "http://#{subdomain+'.' if subdomain.present?}#{domain}#{path}"
  end
end
