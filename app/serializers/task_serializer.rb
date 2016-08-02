class TaskSerializer < ActiveModel::Serializer
  attributes :id, :completed, :failed, :bug_id, :task_type, :result, :user_id, :user_name


  has_many :rules, embed: :ids, embed_in_root: true
  has_many :attachments, embed: :ids, embed_in_root: true

  def user_name
    user = User.find_by id: object.user_id
    user.cvs_username if user
  end

end