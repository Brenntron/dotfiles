module API
  module V1
    module Escalations
      module Sdr
        class Disputes < Grape::API
          include API::V1::Defaults
          include API::BugzillaRestSession

          resource 'escalations/sdr/disputes' do
            before do
              PaperTrail.request.whodunnit = current_user.id if current_user.present?
            end

            desc 'Take list of SDR disputes'
            params do
              requires :dispute_ids, type: Array[Integer]
            end

            patch 'take_disputes' do
              std_api_v2 do
                # authorize!(:update, SenderDomainReputationDispute)
                dispute_ids = permitted_params[:dispute_ids]
                SenderDomainReputationDispute.take_tickets(dispute_ids, user: current_user)

                { user_display_name: current_user.display_name, dispute_ids: dispute_ids }
              end
            end

            desc 'Take single SDR dispute'
            params do
              requires :dispute_id, type: Integer
            end

            patch 'take_dispute/:dispute_id' do
              std_api_v2 do
                dispute = SenderDomainReputationDispute.find(permitted_params[:dispute_id])
                # authorize!(:update, dispute)

                SenderDomainReputationDispute.take_tickets(permitted_params[:dispute_id], user: current_user)

                { user_display_name: current_user.display_name, dispute_id: dispute.id }
              end
            end

            desc 'Return single SDR dispute'
            params do
              requires :dispute_id, type: Integer
            end

            patch 'return_dispute/:dispute_id' do
              std_api_v2 do
                # authorize!(:update, SenderDomainReputationDispute)

                SenderDomainReputationDispute.find(permitted_params[:dispute_id]).return_dispute

                { user_display_name: current_user.display_name, dispute_id: permitted_params[:dispute_id] }
              end
            end

            desc 'Return list of SDR disputes'
            params do
              requires :dispute_ids, type: Array[Integer]
            end

            patch 'return_disputes' do
              std_api_v2 do
                # authorize!(:update, SenderDomainReputationDispute)

                SenderDomainReputationDispute.where(id: permitted_params[:dispute_ids]).each(&:return_dispute)

                { user_display_name: current_user.display_name, dispute_ids: permitted_params[:dispute_ids] }
              end
            end
          end
        end
      end
    end
  end
end
