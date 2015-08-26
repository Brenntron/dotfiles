class ReferenceSerializer < ActiveModel::Serializer
  attributes :id, :reference_data, :created_at, :updated_at , :type, :bugs, :url, :exploits

  def exploits
    exp_ids = []
    object.exploits.each { |e| exp_ids << e.id }
    exp_ids
  end
  def type
    object.reference_type.name if object.reference_type
  end
  def url
    object.reference_type.url.gsub('DATA', reference_data) if object.reference_type
  end
  def bugs # writing a new method because AMS doesn't have has_and_belongs_to_many
    bug_ids = []
    object.bugs.each { |b| bug_ids << b.id }
    bug_ids
  end
end
