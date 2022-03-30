module API
  module V1
    module Escalations
      module CloudIntel
        class Tea < Grape::API
          include API::V1::Defaults

          resource "escalations/cloud_intel/tea" do

            desc 'TEA data'
            params do
              requires :entry, type: String
            end
            post "get_data", root: "whois" do
              std_api_v2 do
                #raise 'Missing Domain/IP to lookup.' unless permitted_params['name'].present?
                #result_data = ::CloudIntel::Whois.whois_query(permitted_params['name'])
                result_data = TalosEscalationAnalysis.get_data_as_hash(params[:entry])
                { data: result_data }
              end
            end
          end
        end
      end
    end
  end
end
