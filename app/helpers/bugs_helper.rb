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

  def bug_filter_indicator(filter)
    'selected' if session[:query] == filter
  end

  def bug_filter_helper
    case session[:query]
      when 'advance-search'
        'Search'
      when ''
        'Bugs'
      else
        session[:query].titleize
    end
  end

  def display_tested_status(rule)
    if rule.tested?
      content_tag(:i, class: "glyphicon glyphicon-plus-sign") { '' }
    else
      '-'
    end
  end

  def get_classifications(class_level)
    Bug.classifications.select{|k,v| v <= Bug.classifications[class_level]}.map{ |k,v| [k.humanize, k] }
  end

  def display_commit_status(bug, rule)
    bug_rule = bug.bugs_rules.where(rule_id: rule).first
    case
      when bug_rule.nil? || bug_rule.svn_result_code.nil?
        '-'
      when bug_rule.svn_success?
        content_tag(:i, class: "glyphicon glyphicon-plus-sign", title: bug_rule.svn_result_output) { '' }
      else
        content_tag(:i, class: "glyphicon glyphicon-minus-sign", title: bug_rule.svn_result_output) { '' }
    end
  end
end
