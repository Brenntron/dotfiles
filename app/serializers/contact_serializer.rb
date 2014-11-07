class ContactSerializer < ActiveModel::Serializer
  attributes :id, :name, :about, :avatar, :created_at, :updated_at
end
