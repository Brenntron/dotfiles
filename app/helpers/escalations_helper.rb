module EscalationsHelper
  STATE_OPTIONS = ['NEW', 'OPEN', 'ASSIGNED', 'DUPLICATE', 'REOPENED', 'PENDING',
                   'FIXED', 'WONTFIX', 'LATER', 'COMPLETED', 'INVALID']

  def esc_state_options(bug)
    remove_list = ['DUPLICATE']
    case bug.state
      when "NEW", "OPEN"
        remove_list << "OPEN" << "REOPENED"
      when "ASSIGNED", "DUPLICATE"
        remove_list << "OPEN"
      when "REOPENED", "PENDING"
        remove_list << "NEW" << "ASSIGNED" << "OPEN"
      when "FIXED", "WONTFIX", "LATER", "INVALID", "COMPLETED"
        remove_list  << "ASSIGNED" << "OPEN"
    end
    if !bug.can_resolve? && bug.state != "PENDING"
      remove_list << "PENDING"
    end
    STATE_OPTIONS.reject{ |so| remove_list.include? so }
  end

  def esc_disabled_state_options(user)

    unless user.has_role?('committer')
      ['FIXED', 'WONTFIX', 'LATER', 'INVALID', 'COMPLETED']
    end

  end
end