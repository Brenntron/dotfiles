class RuleSerializer < ActiveModel::Serializer
  attributes :id, :gid, :sid, :rev, :message, :detection, :state, :average_check,:average_match,:average_nonmatch, :tested, :created_at, :updated_at
end
