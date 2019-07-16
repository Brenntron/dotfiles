module API
  module V1
    module Escalations
      module FileRep
        class EmailTemplates < Grape::API
          include API::V1::Defaults

          resource "escalations/file_rep/email_templates" do

            desc "get an email template"
            params do
              requires :id, type: String, desc: "ID of the email template"
            end

            get ":id", root: "email_template" do
              authorize!(:show, EmailTemplate)
              FileRepEmailTemplate.where(id: permitted_params[:id])
            end

            desc "edit an email template"
            params do
              requires :id, type: Integer, desc: "The email template's id in the database."
              optional :template_name, type: String, desc: "The template name of the template."
              optional :description, type: String, desc: "The description of the email template."
              optional :body, type: String, desc: "The body of the template."
            end

            put ":id", root: "email_template" do
              authorize!(:update, EmailTemplate)
              template = FileRepEmailTemplate.find(permitted_params[:id])
              authorize!(:update, template)
              template.update_attributes(permitted_params)
            end

            desc "create an email template"
            params do
              requires :template_name, type: String, desc: "The email templates template name."
              requires :body, type: String, desc: "The contents of the template."
              optional :description, type: String, desc: "The description of the template."
            end

            post "", root: "email_template" do
              authorize!(:create, EmailTemplate)
              template = FileRepEmailTemplate.create(permitted_params)
              if !template.save
                raise template.errors.full_messages.to_sentence
              end
            end

            desc "delete an email template"
            params do
              requires :id, type: Integer, desc: "The email template's id in the database."
            end

            delete ":id", root: "email_template" do
              authorize!(:delete, EmailTemplate)
              template = FileRepEmailTemplate.find(permitted_params[:id])
              authorize!(:delete, template)
              template.destroy
            end
          end
        end
      end
    end
  end
end
