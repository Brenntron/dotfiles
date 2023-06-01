window.generate_user_api_key = (user_id, user_kerberos) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  user_modal = '#roleModal_' + user_id
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/user_preferences/generateAPIkey/"
    headers: headers
    data:
      id: user_kerberos
    success: (response) ->
      $(user_modal).modal('show')
      $('input[name="user[user_api_key][api_key]"]').val(response['key'])
    error: (response) ->
      std_api_error(response, "There was an error generating API key.", reload: false)
  )
$ ->
  $('#child_id').on 'change', ->
    newTeamMember = $('#child_id option:selected')
    $.ajax
      url: "/escalations/users/#{newTeamMember.val()}/relationships/member_status"
      method: 'GET'
      data: 'new_member': newTeamMember.val()
      success: (res, status, xhr) ->
        if xhr.getResponseHeader('New-Member') == 'false'
          $('.info-alert').eq(0).html( "<p> #{newTeamMember.text()} is on a team already. Are you sure you want to move #{newTeamMember.text()} to another team? </p>" )
          $('#new_member_modal').appendTo('body').modal 'show'
        return
    return

  if $('#user-tab-content').length > 0
    age_col = $('#user-tab-content tbody tr .age-col')
    for col in age_col
      age = moment( $(col).data('age') ).fromNow()
      age_class = ""
      if age != "Invalid date"
        if age == "a few seconds ago" || age == "a few minutes ago" || age.includes("minutes ago")
          age = "<1 hour"

        if age != "<1 hour"
          if age.includes('hour')
            console.log age
            hours = parseInt(age.replace(/[^0-9]/g, ''))
            console.log hours
            if hours > 3 && hours <= 12
              age_class = "ticket-age-over3hr"
            if hours > 12
              age_class = "ticket-age-over12hr"
          else
            age_class = "ticket-age-over12hr"
        $(col).append("<span class='#{age_class}'> #{age}</span>")

  $('.back_btn_user').click ->
    window.location.replace('/escalations/users')

window.setupSelectBoxes = () ->
  addUserButtons = $('.add-user-button')
  for user in addUserButtons
    id = $(user).attr('id')
    strippedId = id.replace('add_user_button_', '')

    $("#users_for_#{strippedId}").selectize({
      create: true,
      sortField: 'text'
    })
