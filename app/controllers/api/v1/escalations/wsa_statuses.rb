module API
  module V1
    module Escalations
      class WsaStatuses < Grape::API
        include API::V1::Defaults

        resource "escalations/wsa_statuses" do

          desc "Returns a list of wsa statuses based on device serial numbers"
          params do
            requires :serials, type: Array
          end
          post "" do
            serials = params['serials']

            Wbrs::WsaStatus.check_statuses(serials)
          end
        end
      end
    end
  end
end
