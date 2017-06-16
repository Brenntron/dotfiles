class UserSerializer < ActiveModel::Serializer
  attributes :id, :kerberos_login, :cvs_username, :cec_username, :display_name, :committer, :email
  has_many :bugs, embed: :ids, embed_in_root: true
end
