class Bug < ActiveRecord::Base
  has_many :attachments, :dependent => :destroy
  has_many :exploits, :through => :references
  has_many :jobs, :dependent => :destroy

  has_and_belongs_to_many :references

  belongs_to :user
  belongs_to :committer, :class_name => 'User'


  private
  def self.import(new_bugs)
    new_bugs['bugs'].each do |item|
      Bug.find_or_create_by(bugzilla_id: item['id']) do |new_record|
        new_record.id        = item['id']
        new_record.state     = Bug.get_state(item['status'], item['resolution'])
        new_record.summary   = item['summary']
        new_record.user      = User.find_or_create_by(email: item['assigned_to'])
        new_record.committer = User.find_or_create_by(email: item['qa_contact'])
      end
    end
  end


  def self.get_state(status, resolution)
    bug_state = "OPEN"
    if status != 'RESOLVED'
      bug_state = "OPEN"
    else
      if resolution.blank?
        bug_state = "OPEN"
      else
        bug_state = resolution
      end
    end
    bug_state
  end
  def self.get_latest()
    Bug.order("created_at").last.created_at
  end

end