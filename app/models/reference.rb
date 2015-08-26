class Reference < ActiveRecord::Base
  has_many :bugs
  has_and_belongs_to_many :rules
  belongs_to :reference_type
  belongs_to :bug
  has_and_belongs_to_many :exploits
end