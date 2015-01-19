class BugSerializer < ActiveModel::Serializer
  attributes :id, :bugzilla_id, :state, :summary, :committer_id, :user_id, :gid, :sid, :rev, :notes, :committer_notes, :created_at, :updated_at
end
