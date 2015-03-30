class UserSerializer < ActiveModel::Serializer
  attributes :id, :cvs_username, :committer, :email
  has_many :bugs, embed: :ids, embed_in_root: true
end
