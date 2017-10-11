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
    remove_list = ['DUPLICATE'] 
    case bug.state
      when "NEW", "OPEN"
        remove_list << "OPEN" << "REOPENED"
      when "ASSIGNED", "DUPLICATE"
        remove_list << "OPEN"
      when "REOPENED", "PENDING"
        remove_list << "NEW" << "ASSIGNED" << "OPEN"
      when "FIXED", "WONTFIX", "LATER", "INVALID"
        remove_list  << "ASSIGNED" << "OPEN" << "PENDING"
    end
    unless bug.can_resolve?
      remove_list << "PENDING"
    end
    unless current_user.has_role?('committer')
      remove_list << "FIXED" << "WONTFIX" << "LATER" << "INVALID"
    end
    STATE_OPTIONS.reject{ |so| remove_list.include? so }
  end

  def disabled_state_options(user)

    unless user.has_role?('committer')
      ['FIXED', 'WONTFIX', 'LATER', 'INVALID']
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

  def display_tested_status(bug, rule)
    if rule.tested_on_bug?(bug)
      icon_success(title: rule.svn_result_output)
    else
      icon_nonstatus
    end
  end

  def classification_selections(class_level)
    Bug.classifications.select{|k,v| v <= Bug.classifications[class_level]}.map{ |k,v| [k.humanize, k] }
  end

  def display_commit_status(bug, rule)
    case
      when rule.svn_result_code.nil?
        icon_nonstatus
      when rule.svn_success?
        icon_success(title: rule.svn_result_output)
      else
        icon_failure(title: rule.svn_result_output)
    end
  end
end
