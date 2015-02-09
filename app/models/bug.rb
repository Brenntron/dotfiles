class Bug < ActiveRecord::Base
  has_many :attachments, :dependent => :destroy
  has_many :exploits, :through => :references
  has_many :jobs, :dependent => :destroy

  has_and_belongs_to_many :references

  belongs_to :user
  belongs_to :committer, :class_name => 'User'

end