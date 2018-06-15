class Complaint < ApplicationRecord
  belongs_to :user
  belongs_to :customer
  has_many :complaint_entries


  def self.can_visit_url?(url)
    can_visit_response = 200
    request = HTTPI::Request.new(url: url)
    response = HTTPI.get(request)
    if response.code == 301
      redirected = Complaint.can_visit_url?(response.headers['Location'])
    end
    if ['SAMEORIGIN'].include?(response.headers['X-Frame-Options'])
      return {status: "FAILED", error: "cannot load page, X-Frame-Options set to #{response.headers['X-Frame-Options']}" }.to_json
    end

    return redirected || { status: "SUCCESS" }.to_json
  end
  
end



