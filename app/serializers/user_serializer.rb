class UserSerializer < ActiveModel::Serializer
  attributes :id, :cvs_username, :committer, :email, :team_member_ids, :manager_ids
  has_many :bugs, embed: :ids, embed_in_root: true
end
