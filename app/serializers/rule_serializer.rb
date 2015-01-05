class RuleSerializer < ActiveModel::Serializer
  attributes :id, :gid, :sid, :rev, :message, :content, :state, :average_check,:average_match,:tested, :created_at, :updated_at
end
