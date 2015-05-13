class RuleSerializer < ActiveModel::Serializer
  attributes :id, :gid, :sid, :rev, :rule_content, :connection, :message, :flow, :detection, :metadata, :class_type, :state, :average_check,:average_match,:average_nonmatch, :tested, :created_at, :updated_at
end
