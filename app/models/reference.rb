class Reference < ActiveRecord::Base
  has_many :bugs
  has_and_belongs_to_many :rules
  has_many :exploits
end