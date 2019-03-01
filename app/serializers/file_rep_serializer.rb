class FileRepSerializer < ActiveModel::Serializer
  attributes :id, :sha256, :email
end
