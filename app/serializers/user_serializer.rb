class UserSerializer < ActiveModel::Serializer
  attributes :id, :cvs_username, :committer, :email
  has_many :bugs, embed: :ids, include: true
end
