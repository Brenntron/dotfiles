module API
  module V1
    module Escalations
      module CloudIntel
        class Whois < Grape::API
          include API::V1::Defaults

          resource "escalations/cloud_intel/whois" do

            desc 'whois lookup'
            params do
              requires :name, type: String
            end
            get "lookup", root: "whois" do
              std_api_v2 do
                result_data = ::CloudIntel::Whois.whois_query(permitted_params['name'])
                { data: result_data }
              end
            end
          end
        end
      end
    end
  end
end
