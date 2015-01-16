class UserSerializer < ActiveModel::Serializer
  attributes :id, :cvs_username, :committer, :email
end
