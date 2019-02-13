
window.std_api_login =() ->
  username = $('form#modal-login-form').find('input[name=username]').val()
  password = $('form#modal-login-form').find('input[name=password]').val()
  url = $('form#modal-login-form').find('input[name=url]').val()
  std_msg_ajax(
    method: 'POST'
    url: url
    data: { username: username, password: password }
    error_prefix: 'Error logging in.'
    success: (response) ->
      $('#login-modal').modal 'hide'
  )


window.top_banner_bugzilla_login =() ->
  username = $('form#top_banner_bugzilla_login_form').find('input[name=username]').val()
  password = $('form#top_banner_bugzilla_login_form').find('input[name=password]').val()
  std_msg_ajax(
    method: 'POST'
    url: '/escalations/api/v1/escalations/bugzilla_rest_login'
    data: { username: username, password: password }
    error_prefix: 'Error logging in.'
    success: (response) ->
      $('form#top_banner_bugzilla_login_form').find('input[name=username]').val('')
      $('form#top_banner_bugzilla_login_form').find('input[name=password]').val('')
      $('#user-settings-dropdown-button').click()
  )


window.check_auth_prompt =(response) ->
  (response.responseJSON != undefined) && (response.responseJSON.prompt != undefined)


window.std_api_unauthenticated =(responseJSON) ->
  msg_div = $('#login-modal').find('#message-text')[0]
  $(msg_div).html('Unable to authenticate to ' + responseJSON['system'])

  prompt_div = $('#login-modal').find('#prompt-text')[0]
  $(prompt_div).html(responseJSON['prompt'])

  $('form#modal-login-form').find('input[name=url]').val(responseJSON['url'])

  $('#login-modal').modal('show')


window.std_api_error =(response, prefix = "Error", options = {}) ->
  if check_auth_prompt(response)
    std_api_unauthenticated(response.responseJSON)
  else
    if response.responseJSON == undefined
      response_lines = response.responseText.split("\n")
      if 10 < response_lines.length
        messages = [ response_lines[0], response_lines[1] ]
      else
        messages = response.responseText.split("\n")
    else if response.responseJSON.messages != undefined
      messages = response.responseJSON.messages
    else if response.responseJSON.message != undefined
      messages = [ response.responseJSON.message ]
    else
      messages = response.responseText.split("\n")

    std_msg_error(prefix, messages, options)


# standard way to call AJAX
# Use std_msg_ajax confirmation message support
# @param [Hash] ajax_data data and options for this AJAX call.
window.std_api_ajax =(ajax_data) ->
  ajax_data.headers = {
    'Token': $('input[name="token"]').val(),
    'Xmlrpc-Token': $('input[name="xml_token"]').val(),
  }
  ajax_data.dataType = 'json'

  if ajax_data.contentType == undefined
    ajax_data.contentType = 'application/json'

  if ajax_data.processData == undefined
    ajax_data.processData = true

  if ajax_data.contentType == 'application/json'
    ajax_data.data = JSON.stringify(ajax_data.data)

  if ajax_data.error_prefix == undefined
    ajax_data.error_prefix = ''
  if ajax_data.failure_reload == undefined
    ajax_data.failure_reload = false
  if ajax_data.success_reload == undefined
    ajax_data.success_reload = false


  if ajax_data.error == undefined
    ajax_data.error =(response) ->
      std_api_error(response, ajax_data.error_prefix, reload: ajax_data.failure_reload)
  if ajax_data.success == undefined
    ajax_data.success =(response) ->
      std_msg_success(ajax_data.success_msg, [], { reload: ajax_data.success_reload })
  $.ajax ajax_data


# standard function to collect input fields and submit an AJAX call.
# @param [Tag] button_tag Use this from the button.
# @param [String] form_selector jQuery selector to find the form.
# @param [String] url the URL for the AJAX call.
# @param [Hash] options data for the AJAX call.
window.std_api_form =(button_tag, form_selector, url, options = {}) ->
  form_tag = $(form_selector)
  options.type = 'POST'
  options.url = url
  options.data = form_tag.serialize()
  std_api_ajax options
