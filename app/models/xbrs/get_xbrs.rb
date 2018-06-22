class Xbrs::GetXbrs < Xbrs::Base


  def self.all
    response = call_json_request(:get, "/v1/rules", body: {})
    # transform the response body into valid JSON, from the YAML provided by the API
    response_body = response.body.gsub("\n---\n",",")
    response_body = response_body.gsub("---\n", "")
    response_body = response_body.prepend("[").concat("]")
    response_body = JSON.parse(response_body)
    response_body
  end

  # def self.all(id)
  #   response = call_json_request(:get, "/v1/rep/wlbl/get/#{id}", body: {})
  #
  #   response_body = JSON.parse(response.body)
  #   new_from_attributes(response_body)
  # end
  #
end