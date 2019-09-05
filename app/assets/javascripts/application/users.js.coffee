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
