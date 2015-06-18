class Job < ActiveRecord::Base
  belongs_to :bug
  belongs_to :user
  has_many :rules
  has_many :attachments

end