class CustomerSerializer < ActiveModel::Serializer
  attributes :id, :name, :company_id
end