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

  $('.back_btn_user').click ->
    window.location.replace('/users')

  $(document).on 'click', '.change_metrics_timeframe', ->
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
