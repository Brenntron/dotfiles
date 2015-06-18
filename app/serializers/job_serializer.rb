class JobSerializer < ActiveModel::Serializer
  attributes :id, :bug_id, :job_type

  has_one :user, embed: :ids, embed_in_root: true
  # has_many :rules, embed: :ids, embed_in_root: true
  has_many :attachments, embed: :ids, embed_in_root: true
end