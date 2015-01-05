class Rule < ActiveRecord::Base
  has_and_belongs_to_many :bugs
  has_and_belongs_to_many :references
  has_and_belongs_to_many :attachments

end