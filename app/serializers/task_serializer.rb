class TaskSerializer < ActiveModel::Serializer
  attributes :id, :completed, :failed, :bug_id, :task_type, :result, :user_id

  has_many :rules, embed: :ids, embed_in_root: true
  has_many :attachments, embed: :ids, embed_in_root: true
end