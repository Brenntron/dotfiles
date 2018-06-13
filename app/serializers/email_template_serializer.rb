class EmailTemplateSerializer < ActiveModel::Serializer
  attributes :id, :template_name, :body, :created_at
end