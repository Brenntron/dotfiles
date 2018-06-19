module API
  module V1
    module Escalations
      module Webrep
        class EmailTemplates < Grape::API
          include API::V1::Defaults

          resource "escalations/webrep/email_templates" do

            desc "get an email template"
            params do
              requires :id, type: String, desc: "ID of the email template"
            end

            get ":id", root: "email_template" do
              EmailTemplate.where(id: permitted_params[:id])
            end

            desc "edit an email template"
            params do
              requires :id, type: Integer, desc: "The email template's id in the database."
              optional :template_name, type: Integer, desc: "The template name of the template."
              optional :body, type: String, desc: "The body of the template."
            end

            put ":id", root: "email_template" do
              EmailTemplate.update_attributes(permitted_params)
            end

            desc "create an email template"
            params do
              requires :template_name, type: String, desc: "The email templates template name."
              requires :body, type: String, desc: "The contents of the template."
              optional :description, type: String, desc: "The description of the template."
            end

            post "", root: "email_template" do
              EmailTemplate.create(permitted_params)
            end

            desc "delete an email template"
            params do
              requires :id, type: Integer, desc: "The email template's id in the database."
            end

            delete ":id", root: "email_template" do
              EmailTemplate.destroy(permitted_params[:id])
            end
          end
        end
      end
    end
  end
end