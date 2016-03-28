class BugSerializer < ActiveModel::Serializer
  attributes :id, :bugzilla_id, :state, :status, :resolution, :summary, :committer_id, :user_id, :editor_id, :gid, :sid, :rev, :notes, :product, :component, :description, :version, :research_notes, :committer_notes, :created_at, :updated_at, :assigned_at, :pending_at, :resolved_at, :reopened_at, :work_time, :review_time, :rework_time,:attachments
  has_many :notes, embed: :ids, embed_in_root: true
  has_many :attachments, embed: :ids, embed_in_root: true
  has_many :rules, embed: :ids, embed_in_root: true
  has_many :references, embed: :ids, embed_in_root: true
  has_many :tasks, embed: :ids, embed_in_root: true
  has_many :exploits, embed: :ids, embed_in_root: true
  def editor_id
    object.user_id
  end

end