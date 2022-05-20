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
                authorize!(:update, SenderDomainReputationDispute)
                dispute_ids = permitted_params[:dispute_ids]
                SenderDomainReputationDispute.take_tickets(dispute_ids, user: current_user)

                { username: current_user.cvs_username, dispute_ids: dispute_ids }
              end
            end

            desc 'Take single SDR dispute'
            params do
              requires :dispute_id, type: Integer
            end

            patch 'take_dispute/:dispute_id' do
              std_api_v2 do
                authorize!(:update, SenderDomainReputationDispute)

                SenderDomainReputationDispute.take_tickets(permitted_params[:dispute_id], user: current_user)
                { username: current_user.cvs_username, dispute_id: permitted_params[:dispute_id] }
              end
            end

            desc 'Return single SDR dispute'
            params do
              requires :dispute_id, type: Integer
            end

            patch 'return_dispute/:dispute_id' do
              std_api_v2 do
                authorize!(:update, SenderDomainReputationDispute)

                SenderDomainReputationDispute.find(permitted_params[:dispute_id]).return_dispute
                { username: current_user.cvs_username, dispute_id: permitted_params[:dispute_id] }
              end
            end

            desc 'Return list of SDR disputes'
            params do
              requires :dispute_ids, type: Array[Integer]
            end

            patch 'return_disputes' do
              std_api_v2 do
                authorize!(:update, SenderDomainReputationDispute)

                SenderDomainReputationDispute.where(id: permitted_params[:dispute_ids]).each(&:return_dispute)

                { username: current_user.cvs_username, dispute_ids: permitted_params[:dispute_ids] }
              end
            end

            desc 'get all disputes'
            params do

            end

            get "" do
              authorize!(:index, SenderDomainReputationDispute)


            end

            desc 'create a dispute'
            params do

            end

            post "" do
              std_api_v2 do

              end
            end

            desc 'update a dispute'
            params do

            end
            put ":id" do

            end

            desc 'delete a dispute'
            params do
            end

            delete "" do
              # TODO access control when this is implmented
            end



            desc "Change assignee of a group of dispute IDs"
            params do

            end
            post "change_assignee" do
              authorize!(:update, SenderDomainReputationDispute)
              disputes = SenderDomainReputationDispute.assign(params[:dispute_ids], user: params[:new_assignee])
              {:status => "success", :data => disputes}.to_json
            end

            desc "Remove assignee from a group of dispute IDs (revert to vrtincoming)"
            params do
              requires :dispute_ids, type: Array[Integer], desc: "analyst-console database id"
            end
            post "unassign_all" do
              json_packet = []
              vrt = User.where(email: 'vrt-incoming@sourcefire.com').first
              params[:dispute_ids].each do |dispute|
                SenderDomainReputationDispute.where(id: dispute).update_all(user_id: vrt.id)
                d = SenderDomainReputationDispute.find_by(id: dispute)
                if d.status == SenderDomainReputationDispute::STATUS_ASSIGNED
                  d.update(status: SenderDomainReputationDispute::STATUS_NEW, case_assigned_at: nil)
                end

                raise "This record changed while you were editing. To continue this operation anyway, reload the page and make your assignment again." unless d.user_id == vrt.id
                json_packet << d
              end
              {:status => "success", :data => json_packet}.to_json
            end

            params do
              requires :dispute_ids, type: Array[Integer]
            end
            patch 'take_disputes' do
              std_api_v2 do
                authorize!(:update, SenderDomainReputationDispute)

                dispute_ids = permitted_params['dispute_ids']
                SenderDomainReputationDispute.take_tickets(dispute_ids, user: current_user)

                { username: current_user.cvs_username, dispute_ids: dispute_ids }

              end
            end

            params do
              requires :dispute_id, type: Integer
            end
            patch 'return_dispute/:dispute_id' do
              std_api_v2 do

              end
            end

            params do
              requires :field_data, type: Hash
            end
            patch 'entries/field_data' do
              std_api_v2 do
                authorize!(:update, Dispute)

                DisputeEntry.update_from_field_data(permitted_params['field_data'])
                DisputeEntry.send_status_updates(permitted_params['field_data'])

                permitted_params['field_data'].each do |index, entry|
                  if entry.length == 3 && entry.last['field'] == 'resolution_comment' && !entry.last['new'].empty?
                    comment = entry.last["new"]
                    dispute_entry_id = index
                    Dispute.create_note(current_user, comment, dispute_entry_id)
                  end
                end

                true
              end
            end

            params do
              requires :dispute_id, type: Integer
              requires :comment, type: String
            end
            post 'create_note' do
              std_api_v2 do

              end
            end

            params do
              requires :dispute_ids, type: Array[String]
              requires :status, type: String
              optional :resolution, type: String
              optional :comment, type: String
            end

            post 'set_disputes_status' do

              authorize!(:update, SenderDomainReputationDispute)

              status = params[:status]
              resolution = ""
              comment = ""
              if params[:resolution].present?
                resolution = params[:resolution]
              else
                resolution = nil
              end

              if params[:comment].present?
                if status == SenderDomainReputationDispute::STATUS_RESOLVED
                  comment = status + ' : ' + resolution + ' - ' + params[:comment]
                else
                  comment = status + ' - ' + params[:comment]
                end
              end

              disputes = SenderDomainReputationDispute.where(id: params['dispute_ids'])

              SenderDomainReputationDispute.process_status_changes(disputes, status, resolution, comment, current_user)
              {:status => "success"}.to_json
            end

            params do
              requires :dispute_id, type: Integer
            end
            get 'dispute_status/:dispute_id' do
              std_api_v2 do
                dispute = SenderDomainReputationDispute.find(permitted_params['dispute_id'])
                status = dispute.status
                if dispute.status == SenderDomainReputationDispute::STATUS_RESOLVED
                  comment = dispute.resolution_comment
                  resolution = dispute.resolution
                else
                  comment = nil
                  resolution = nil
                end


                {:status => status, :resolution => resolution, :comment => comment}.to_json
              end
            end

            params do
              requires :dispute_id, type: Integer
            end
            get 'dispute_resolution/:dispute_id' do
              std_api_v2 do
                dispute = SenderDomainReputationDispute.find(permitted_params['dispute_id'])
                resolution = dispute.resolution

                if dispute.resolution_comment.present?
                  resolution_comment = dispute.resolution_comment
                else
                  resolution_comment = ''
                end

                {:resolution => resolution, :resolution_comment => resolution_comment}.to_json
              end
            end

            params do
              requires :dispute_entry_id, type: Integer
            end
            get 'dispute_entry_status/:dispute_entry_id' do
              std_api_v2 do
                dispute_entry = DisputeEntry.find(permitted_params['dispute_entry_id'])
                status = dispute_entry.status
                {:status => status}.to_json
              end
            end

            params do
              requires :dispute_entry_id, type: Integer
            end
            get 'dispute_entry_resolution/:dispute_entry_id' do
              std_api_v2 do
                dispute_entry = DisputeEntry.find(permitted_params['dispute_entry_id'])

                resolution = dispute_entry.resolution

                if dispute_entry.resolution_comment.present?
                  resolution_comment = dispute_entry.resolution_comment
                else
                  resolution_comment = ''
                end

                {:resolution => resolution}.to_json
              end
            end

            params do
              requires :duplicate_dispute_id, type: Integer
            end
            post ':dispute_id/duplicate_disputes' do
              std_api_v2 do
                authorize!(:update, Dispute)
                dispute = Dispute.find(params['dispute_id'])
                resolved_at = Time.now
                authorize!(:update, dispute)
                dispute.update!(related_id: permitted_params['duplicate_dispute_id'],
                                related_at: DateTime.now,
                                status: Dispute::CLOSED,
                                resolution: Dispute::DUPLICATE,
                                case_closed_at: resolved_at,
                                case_resolved_at: resolved_at)
                true
              end
            end

            desc 'Autopopulate fields on Advanced Search'
            get 'autopopulate_advanced_search' do
              case_owners = User.joins(:sender_domain_reputation_disputes).where.not(cvs_username: nil).order(cvs_username: :asc).uniq
              all_constants = SenderDomainReputationDispute.constants
              statuses = all_constants.select { |x| x.match?('STATUS') }.map { |name| SenderDomainReputationDispute.const_get(name) }
              submitter_types = all_constants.select { |x| x.match?('SUBMITTER_TYPE') }.map { |name| SenderDomainReputationDispute.const_get(name) }
              contacts = Customer.all.order(name: :asc)
              companies = Company.all.order(name: :asc)
              priorities = SenderDomainReputationDispute.pluck(:priority).uniq.compact
              # TODO: add resolutions to SenderDomainReputationDispute model and use it there
              resolutions = [Dispute::STATUS_RESOLVED_FIXED_FP, Dispute::STATUS_RESOLVED_FIXED_FN, Dispute::STATUS_RESOLVED_UNCHANGED,
                             Dispute::STATUS_RESOLVED_INVALID, Dispute::STATUS_RESOLVED_TEST, Dispute::STATUS_RESOLVED_OTHER]
              platforms = Platform.all.order(public_name: :asc).map { |m| { id: m.id, public_name: m.public_name } }
              render json: { case_owners: case_owners, statuses: statuses, submitter_types: submitter_types,
                            contacts: contacts, companies: companies, resolutions: resolutions,
                            platforms: platforms, priorities: priorities }
            end

            desc 'Auto-populate fields on New Dispute'
            get 'populate_new_dispute_fields' do
              assignees = User.joins(roles: :org_subset).where(org_subsets: { name: 'webrep' }).distinct.order(:cvs_username)

              render json: {assignees: assignees}
            end



            params do
              requires :id, type: Integer
            end

            post 'recover_dispute' do
              dispute_to_recover = Dispute.find(params[:id])
              results = dispute_to_recover.rebuild_from_packet
              if results[:errors].present?
                return {:status => "error", :errors => results[:errors], :messages => results[:messages]}
              else
                return {:status => "success", :messages => results[:messages]}
              end
            end


            params do
              requires :id, type: Integer
            end

            get 'suggested_subject' do
              attachment = SenderDomainReputationDisputeAttachment.find(params[:id])
              if attachment.suggested_subject.present?
                return {:status => "success", :messages => attachment.suggested_subject}
              else
                return {:status => "success", :messages => ""}
              end
            end

            params do
              requires :id, type: Integer
              requires :subject, type: String
              requires :tag, type: String
              requires :email, type: String
            end

            post 'submit_to_corpus' do
              attachment = SenderDomainReputationDisputeAttachment.find(params[:id])
              attachment.send_to_corpus(params[:email], params[:subject], params[:tag], bugzilla_session)

            end
          end
        end
      end
    end
  end
end
