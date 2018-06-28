module WebrepHelper

  def whodunnit_helper(version)
   user = User.where(id: version.whodunnit).first
   user.present? ? user.cec_username : 'Automated'
  end

  def field_changeset_handler(field, changed_from)
    display_field = field == 'comment' ? 'Note' : field
    if changed_from
      "#{display_field.humanize.capitalize} changed from"
    else
      "#{display_field.humanize.capitalize} changed"
    end
  end

end