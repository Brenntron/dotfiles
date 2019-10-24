module ApplicationHelper
  def bugzilla_rest_token
    session['bugzilla_rest_token']
  end

  def bugzilla_api_key
    current_user&.bugzilla_api_key
  end

  def bugzilla_rest_logged_in?(session)
    session.logged_in?
  end

  def bugzilla_rest_login_icon(session)
    if bugzilla_rest_logged_in?(session)
      content_tag(:span, '', class: ['bugzilla-status', 'bugzilla-logged-in', 'esc-tooltipped'], title: 'Logged into Bugzilla')
    else
      content_tag(:span, '', class: ['bugzilla-status', 'bugzilla-logged-out', 'esc-tooltipped'], title: 'Not logged into Bugzilla')
    end
  end

  def bootstrap_class_for(flash_type)
    case flash_type
      when "success"
        "alert-success"   # Green
      when "error"
        "alert-danger"    # Red
      when "alert"
        "alert-warning"   # Yellow
      when "notice"
        "alert-info"      # Blue
      else
        flash_type.to_s
    end
  end

  def icon_smtp(**html_attr)
    content_tag(:i, class: "glyphicon glyphicon-envelope", **html_attr) { '' }
  end

  def icon_copy(**html_attr)
    content_tag(:i, class: "glyphicon glyphicon-copy", **html_attr) { '' }
  end

  def icon_paste(**html_attr)
    content_tag(:i, class: "glyphicon glyphicon-paste", **html_attr) { '' }
  end

  def icon_success(**html_attr)
    content_tag(:span, class: "glyphicon glyphicon-ok", **html_attr) { '' }
  end

  def icon_failure(**html_attr)
    content_tag(:span, class: "glyphicon glyphicon-remove", **html_attr) { '' }
  end

  def icon_nonstatus(**html_attr)
    content_tag(:span, class: "glyphicon glyphicon-minus", **html_attr) { '' }
  end


  def is_rule_user?
    current_user&.has_role?(['admin', 'analyst', 'committer', 'build coordinator', 'manager'])
  end

  def role_options_for(user)
    if user.has_role?('admin')
      Role.all
    else
      Role.exclude_admin
    end
  end

  def link_for_manager(session_user, viewed_user, display_name:)
    if session_user.has_role?('admin')
      link_to display_name, escalations_user_path(viewed_user.parent), class: 'related-username'
    else
      viewed_user.parent.cvs_username
    end
  end
end
