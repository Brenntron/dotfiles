class FileReputationDisputeSerializer < ActiveModel::Serializer
  attributes :id, :file_rep_name, :sha256_checksum, :email
end
