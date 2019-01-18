$ ->
  $('.expand-manager-row-button').click ->
    parent_button = this
    manager_id = $(parent_button).attr('data-user-manager')
    $(parent_button).toggleClass('up')

    $('.manage-child-row').each ->
      row = this
      if $(row).attr('data-user-child').includes(manager_id)
#       is a child row
        unless $(parent_button).hasClass('up')
          nested_button = $(row).find('.expand-manager-row-button')
          if $(nested_button).length > 0
  #          child is a manager
            unless $(nested_button).hasClass('up')
              $(row).hide()
          else
            $(row).hide()
          $(row).hide()
        else
          $(row).show()

