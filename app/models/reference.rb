class Reference < ActiveRecord::Base
  has_and_belongs_to_many :bugs
  has_and_belongs_to_many :rules
  has_and_belongs_to_many :exploits
end