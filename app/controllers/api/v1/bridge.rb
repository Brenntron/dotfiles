module API
  module V1
    class Bridge < Grape::API
      include API::V1::Defaults

      resource :bridge do

        desc "Create a saved search"
        params do
          required :payload, type: String, desc: "bridge payload"
        end
        post "" do
          begin

            payload = JSON.parse(params[:payload])
            envelope = params[:envelope]

            Dispute.process_bridge_payload(payload)

            DisputeEmail.process_bridge_payload(payload)  
         
            #Bug.process_bridge_payload(payload) 


          rescue Exception => e
            Rails.logger.error "failed to process bridge message"
            Rails.logger.error $!
            Rails.logger.error $!.backtrace.join("\n")
          end
        end

      end
    end
  end
end
