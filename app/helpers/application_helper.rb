module ApplicationHelper
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

  def glyph_success(**html_attr)
    content_tag(:span, class: "glyphicon glyphicon-ok", **html_attr) { '' }
  end

  def glyph_failure(**html_attr)
    content_tag(:span, class: "glyphicon glyphicon-remove", **html_attr) { '' }
  end

  def glyph_nonstatus(**html_attr)
    content_tag(:span, class: "glyphicon glyphicon-minus", **html_attr) { '' }
  end


  def role_options_for(user)
    if user.has_role?('admin')
      Role.all
    else
      Role.exclude_admin
    end
  end

  def link_for_manager(session_user, viewed_user)
    if session_user.has_role?('admin')
      link_to viewed_user.parent.cvs_username, user_path(viewed_user.parent)
    else
      viewed_user.parent.cvs_username
    end
  end
end
