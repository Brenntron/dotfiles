module BugsHelper

  def allowed_editors(bug)
    User.all.reject { |u| u.id == bug.committer_id }
  end

  def allowed_committers(bug)
    User.with_role('committer').reject { |u| u.id == bug.user_id }
  end

  def set_bug_color(bug)
    if ["P1", "P2"].include?(bug.priority)
      if ["NEW", "ASSIGNED", "REOPENED"].include?(bug.state)
        'bg-danger'
      elsif ["FIXED", "WONTFIX", "LATER"].include?(bug.state)
         'bg-success'
      else
        ''
      end
    end
  end
end