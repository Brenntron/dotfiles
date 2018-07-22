class ComplaintEntry < ApplicationRecord
  belongs_to :complaint

  RESOLVED = "RESOLVED"
  NEW = "NEW"

  STATUS_RESOLVED_FIXED_FN = "FIXED FN"
  STATUS_RESOLVED_FIXED_FP = "FIXED FP"
  STATUS_RESOLVED_FIXED_UNCHANGED = "UNCHANGED"

  def location_url
    "http://#{subdomain+'.' if subdomain.present?}#{domain}#{path}"
  end
end
