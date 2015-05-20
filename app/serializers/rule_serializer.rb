class RuleSerializer < ActiveModel::Serializer
  attributes :id, :gid, :sid, :rev, :rule_content, :connection, :message, :flow, :detection, :metadata, :class_type, :average_check,:average_match,:average_nonmatch, :state, :tested, :committed, :created_at, :updated_at
  has_many :references, embed: :ids, embed_in_root: true
end