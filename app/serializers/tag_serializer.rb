class TagSerializer < ActiveModel::Serializer
  attributes :id, :name, :bugs
  def bugs # writing a new method because AMS doesn't have has_and_belongs_to_many
    bug_ids = []
    object.bugs.each { |b| bug_ids << b.id }
    bug_ids
  end
end