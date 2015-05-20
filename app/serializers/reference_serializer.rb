class ReferenceSerializer < ActiveModel::Serializer
  attributes :id, :reference_data, :created_at, :updated_at , :type, :url
  #belongs_to :rule

  def type
    object.reference_type.name if object.reference_type
  end
  def url
    object.reference_type.url.gsub('DATA', reference_data) if object.reference_type
  end
end
