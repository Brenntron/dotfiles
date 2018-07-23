module API
  module V1
    class RulehitResolutionMailerTemplates < Grape::API
      include API::V1::Defaults

      resource :rulehit_resolution_mailer_templates do
        # before do
        #   PaperTrail.whodunnit = current_user.id if current_user.present?
        # end

        desc "get a mailer template corresponding to a rulehit"
        params do
          requires :rulehit_id, type: Integer, desc: "Bugzilla id."
        end
        get 'make_rulehit_mail/:rulehit_id' do
          # TODO This propably should have some authorization, but I do not understand what this does.
          # authorize!(:import, ResearchBug)

          Rails.logger.debug("Retrieving rulehit mailer template...")
          # progress_bar = Event.create(user: current_user.display_name, action: "import_bug:#{params[:id]}", description: "#{request.headers["Token"]}", progress: 10)

          begin
            rulehit = DisputeRuleHit.where(id: params['rulehit_id']).first
            return {:error => 'Rulehit not found'}.to_json unless rulehit
            rh_mailer_template = RulehitResolutionMailerTemplate.where(mnemonic: rulehit.name).first # TODO: This is PROBABLY .mnemonic here rather than name but we will clear that up later
            return {:error => 'No template with that mnemonic!'}.to_json unless rh_mailer_template
            parent_dispute = DisputeEntry.where(id: rulehit.dispute_entry_id).first
            return {:error => 'No DisputeEntry found! can\'t make hostname!'}.to_json unless parent_dispute

            # TODO: This needs to be cleaned up big time, it's too verbose but right now we just need it to work
            hoststring = "NOHOST"

            unless parent_dispute.hostname.nil?
              hoststring = parent_dispute.hostname
            end

            unless parent_dispute.ip_address.nil?
              hoststring = parent_dispute.ip_address
            end
            rh_mailer_template.subject = rh_mailer_template.subject.gsub '%%HOSTNAME%%', hoststring
            rh_mailer_template.body = rh_mailer_template.body.gsub '%%HOSTNAME%%', hoststring

            return rh_mailer_template.to_json

          rescue Exception => e
            Rails.logger.error "Something went wrong! Failed to retrieve template."
            Rails.logger.error $!
            Rails.logger.error $!.backtrace.join("\n")
            error = "Something went wrong! Failed to retrieve template."
            {:error => error}.to_json
          end

        end


      end
    end
  end
end
