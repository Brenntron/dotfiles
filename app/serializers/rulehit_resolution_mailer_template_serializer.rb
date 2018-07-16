class RulehitResolutionMailerTemplateSerializer < ActiveModel::Serializer
  attributes :id, :mnemonic, :to, :cc, :subject, :body
end
