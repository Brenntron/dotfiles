window.escalation_acknowledge = (this_tag,bug_id) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/bugs/' + bug_id + '/acknowledge'
    method: 'PATCH'
    headers: headers
    data: { }
    success: (response) ->
      $('#acknowledge_esc_form_button').hide()
  , this)

window.take_escalation_acknowledge = (this_tag,bug_id) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $("#take-bug-"+bug_id).hide()
  $("#bug-wait-"+bug_id).show()
  $('#loading_image').removeClass('hidden').show()
  $.ajax {
    url: '/api/v1/bugs/'+bug_id+'/subscribe-acknowledge'
    data: {committer: false}
    method: 'post'
    headers: headers
    success: (response) ->
      location.reload()
    error: (response) ->
      alert ("Sorry, you can not take this bug\n" + response.responseJSON.error)
      location.reload()
  }