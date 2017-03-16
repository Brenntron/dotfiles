module BugsHelper

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

  STATE_OPTIONS = ['NEW', 'OPEN', 'ASSIGNED', 'DUPLICATE', 'REOPENED', 'PENDING',
                   'FIXED', 'WONTFIX', 'LATER', 'INVALID']

  def state_options(bug)
    if bug.can_set_pending? || bug.state == 'PENDING'
      STATE_OPTIONS
    else
      STATE_OPTIONS.reject{ |so| so == "PENDING" }
    end
  end

  def disabled_state_options(user)
    if user.has_role?('committer')
      ['NEW']
    else
      ['FIXED', 'WONTFIX', 'LATER', 'INVALID', 'NEW']
    end
  end
end