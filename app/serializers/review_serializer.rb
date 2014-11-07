class ReviewSerializer < ActiveModel::Serializer
  attributes :id, :text, :reviewedAt, :created_at, :updated_at
end
