class BugSerializer < ActiveModel::Serializer
  attributes :id, :bugzilla_id, :state, :summary, :user_id, :committer_id, :gid, :sid, :rev, :notes, :committer_notes, :created_at, :updated_at
end
