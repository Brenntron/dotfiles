$ ->
  $('#relationship_team_member_id').on 'change', ->
    newTeamMember = $('#relationship_team_member_id option:selected')
    $.ajax
      url: 'relationships/member_status'
      method: 'GET'
      data: 'new_member': newTeamMember.val()
      success: (res, status, xhr) ->
        if xhr.getResponseHeader('New-Member') == 'false'
          $('.modal-body').eq(0).html( "<p> #{newTeamMember.text()} is on a team already. Users can be members of multiple teams. </p>" )
          $('#new_member_modal').appendTo('body').modal 'show'
        return
    return
