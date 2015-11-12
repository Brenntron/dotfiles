class UserSerializer < ActiveModel::Serializer
  attributes :id, :kerberos_login, :cvs_username, :cec_username, :display_name, :committer, :email, :team_member_ids, :manager_ids
  has_many :bugs, embed: :ids, embed_in_root: true
end
