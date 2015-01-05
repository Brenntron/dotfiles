class Attachment < ActiveRecord::Base
  belongs_to :bug
  has_and_belongs_to_many :rules
  has_many :exploits
end