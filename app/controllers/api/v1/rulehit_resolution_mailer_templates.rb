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
          # authorize!(:import, ResearchBug)

          Rails.logger.debug("Retrieving rulehit mailer template...")
          # progress_bar = Event.create(user: current_user.display_name, action: "import_bug:#{params[:id]}", description: "#{request.headers["Token"]}", progress: 10)

          begin
            rulehit = DisputeRuleHit.where(id: params['rulehit_id']).first
            return {:error => 'Rulehit not found'}.to_json unless rulehit
            rh_mailer_template = RulehitResolutionMailerTemplate.where(mnemonic: rulehit.mnemonic).first
            return {:error => 'No template with that mnemonic!'}.to_json unless rh_mailer_template

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
