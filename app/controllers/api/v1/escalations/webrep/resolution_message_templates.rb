module API
  module V1
    module Escalations
      module Webrep
        class ResolutionMessageTemplates < Grape::API
          include API::V1::Defaults
          resource "escalations/webrep/resolution_message_templates" do

            desc "get a resolution message template"
            params do
              requires :id, type: String, desc: "ID of the resolution message template"
            end

            get ":id", root: "resolution_message_template" do
              authorize!(:show, ResolutionMessageTemplate)
              ResolutionMessageTemplate.find(permitted_params[:id])
            end

            desc "edit an resolution message template"
            params do
              requires :id, type: Integer, desc: "The resolution message template's id in the database."
              optional :name, type: String, desc: "The template name of the template."
              optional :description, type: String, desc: "The description of the resolution message template."
              optional :body, type: String, desc: "The body of the template."
            end

            put ":id", root: "resolution_message_template" do
              authorize!(:update, ResolutionMessageTemplate)
              template = ResolutionMessageTemplate.find(permitted_params[:id])
              authorize!(:update, template)
              template.update_attributes(permitted_params)
            end

            desc "create an resolution message template"
            params do
              requires :name, type: String, desc: "The resolution message template's template name."
              requires :body, type: String, desc: "The contents of the template."
              optional :description, type: String, desc: "The description of the template."
            end

            post "", root: "resolution_message_template" do
              authorize!(:create, ResolutionMessageTemplate)
              template = ResolutionMessageTemplate.create(permitted_params)
              if !template.save
                raise template.errors.full_messages.to_sentence
              end
            end

            desc "delete an resolution message template"
            params do
              requires :id, type: Integer, desc: "The resolution message template's id in the database."
            end

            delete ":id", root: "resolution_message_template" do
              authorize!(:delete, ResolutionMessageTemplate)
              template = ResolutionMessageTemplate.find(permitted_params[:id])
              authorize!(:delete, template)
              template.destroy
            end
          end
        end
      end
    end
  end
end
