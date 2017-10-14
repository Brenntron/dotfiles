require 'rake'
class DelayedJob < ApplicationRecord

  def self.run_rake(task_name,current_user,bugzilla_session)
    load File.join(Rails.root, 'lib', 'tasks', 'import_bugs.rake')
    Rake::Task[task_name].invoke(current_user, bugzilla_session)
  end

end