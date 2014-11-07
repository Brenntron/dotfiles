class ProductSerializer < ActiveModel::Serializer
  attributes :id, :title, :price, :description, :isOnSale, :image, :created_at, :updated_at
end
