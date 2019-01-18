$ ->
  $('.expand-manager-row-button').click ->
    parent_button = this
    manager_id = $(parent_button).attr('data-user-manager')
    $(parent_button).toggleClass('up')

#    Hide all the proper rows
    $('.manage-child-row').each ->
      row = this
      if $(row).attr('data-user-child').includes(manager_id)
        unless $(parent_button).hasClass('up')
          nested_button = $(row).find('.expand-manager-row-button')
          if $(nested_button).length > 0
            unless $(nested_button).hasClass('up')
              $(row).hide()
          else
            $(row).hide()
          $(row).hide()
        else
          $(row).show()

    hidden_rows = $('.manage-child-row:hidden').length
    original_rowspan = $("#team-cell").attr('data-rowspan')
    if hidden_rows == 0
      $("#team-cell").attr('rowspan', original_rowspan)
    else
      new_rowspan = original_rowspan - hidden_rows
      $("#team-cell").attr('rowspan', new_rowspan)
