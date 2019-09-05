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


  $('.select-team-members').on 'change', ->
    team_member_id = $(this).val()
    team_member_name = $(this).children('option:selected').text()
    $.ajax
      url: "/escalations/users/#{team_member_id}/relationships/member_status"
      method: 'GET'
      data: 'new_member': team_member_id
      success: (res, status, xhr) ->
        if xhr.getResponseHeader('New-Member') == 'false'
          $('.info-alert').eq(0).html( "<p> #{team_member_name} is on a team already. Are you sure you want to move #{team_member_name} to another team? </p>" )
          $('#new_member_modal').appendTo('body').modal 'show'
        return
    return
