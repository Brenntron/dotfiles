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
end