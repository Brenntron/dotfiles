
window.submit_task = ()->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

  task = $('.task-name').val()
  args = $('.task-args').val()


  $.ajax(
    url: '/escalations/api/v1/escalations/admin/tools/execute_task'
    method: 'POST'
    headers: headers
    data: {'task': task, 'args': args}

    success: (response) ->
      json = $.parseJSON(response)
      if json.status == 'error'
        $('#task-msg').html("ERROR:" + json.message)
      else
        $('#task-msg').html("Your task has successfully started.  Check morsel for any output")
        $('#morsel-output').html("<a href='/admin/morsels/" + json.morsel_id + "'>here</a>")
    error: (response) ->
      $('#task-msg').html('An error occurred attempting to execute task')
  , this)

$ ->
  $("#execute-task-button").click ->
    window.submit_task();