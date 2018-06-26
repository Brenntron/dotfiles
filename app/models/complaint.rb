class Complaint < ApplicationRecord
  belongs_to :user
  belongs_to :customer
  has_many :complaint_entries


  def self.can_visit_url?(url)
    begin
    request = HTTPI::Request.new(url: url)
    response = HTTPI.get(request)
    if response.code == 301
      redirected = Complaint.can_visit_url?(response.headers['Location'])
    end
    if ['SAMEORIGIN'].include?(response.headers['X-Frame-Options'])
      return {status: 403, error: "cannot load page, X-Frame-Options set to #{response.headers['X-Frame-Options']}" }.to_json
    end

    return redirected || { status: "SUCCESS" }.to_json

    rescue Curl::Err::HostResolutionError => e
      return {status: 404, error: e.message}.to_json
    end
  end

end



