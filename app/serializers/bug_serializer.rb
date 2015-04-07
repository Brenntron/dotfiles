class BugSerializer < ActiveModel::Serializer
  attributes :id, :bugzilla_id, :state, :summary, :committer_id, :user_id, :gid, :sid, :rev, :notes, :product, :component, :description, :version, :research_notes, :committer_notes, :created_at, :updated_at
  has_many :notes, embed: :ids, embed_in_root: true
  has_many :attachments, embed: :ids, include: true
end
