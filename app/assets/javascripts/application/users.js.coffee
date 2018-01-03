$ ->
  $('#child_id').on 'change', ->
    newTeamMember = $('#child_id option:selected')
    $.ajax
      url: 'relationships/member_status'
      method: 'GET'
      data: 'new_member': newTeamMember.val()
      success: (res, status, xhr) ->
        if xhr.getResponseHeader('New-Member') == 'false'
          $('.info-alert').eq(0).html( "<p> #{newTeamMember.text()} is on a team already. Are you sure you want to move #{newTeamMember.text()} to another team? </p>" )
          $('#new_member_modal').appendTo('body').modal 'show'
        return
    return

  $('#user-bugs').click ->
    user_id = $(this).attr('value')
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    alert('This will import ALL of your bugs from Bugzilla. All bugs imported with ' +
        'this method will need to be "resunk", as needed, in order to pull in attachments, rules and history.')
    $('#user-bugs').hide()
    $('#importing_image').removeClass('hidden').show()
    $.ajax(
      url: '/api/v1/bugs/by_user/' + user_id
      headers: headers
      method: 'GET'
      success: ->
        window.location.reload
      error: ->
        alert('Something went wrong while importing your bugs.')
    ).done (response) ->
      window.location.reload()
    return

  $('.back_btn_user').click ->
    window.location.replace('/users')

  $(document).on 'click', '.change_metrics_timeframe', (e)->
    e.preventDefault()
    $('#change_metrics_timeframe, #change_metrics_timeframe_form').toggle()


    $("#change_metrics_timeframe_form").submit (e)->
      e.preventDefault()
      headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
      id = $('input[name="current_user"]').val()
      timeframe = $('#user_metrics_timeframe option:selected').val()
      $.ajax(
        url: '/api/v1/users/' + id
        method: 'PUT'
        headers: headers
        data:
          id: id,
          metrics_timeframe: timeframe
      ).done (response) ->
        window.location.reload()
        return