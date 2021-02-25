module API
  module V1
    module Escalations
      class WsaStatuses < Grape::API
        include API::V1::Defaults

        resource "escalations/wsa_statuses" do

          desc "Returns a list of wsa statuses based on device serial numbers"
          params do
            optional :serials, type: Array
            optional :companies, type: Array
          end
          post "" do
            serials = params['serials']
            companies = params['companies']

            Wbrs::WsaStatus.check_statuses(serials, companies)
          end
        end
      end
    end
  end
end
