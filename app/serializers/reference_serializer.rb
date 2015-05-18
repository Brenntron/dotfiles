class ReferenceSerializer < ActiveModel::Serializer
  attributes :id, :reference_data, :created_at, :updated_at , :type
  #belongs_to :rule

  def type
    object.reference_type.name if object.reference_type
  end
end
