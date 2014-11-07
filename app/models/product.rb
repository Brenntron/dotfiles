class Product < ActiveRecord::Base
  has_many :reviews
  belongs_to :contact
end
