class FileRepEmailTemplateSerializer < ActiveModel::Serializer
  attributes :id, :template_name, :body, :description, :created_at
end