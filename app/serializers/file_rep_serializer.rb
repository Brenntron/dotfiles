class FileRepSerializer < ActiveModel::Serializer
  attributes :id, :file_rep_name, :sha256, :email
end
