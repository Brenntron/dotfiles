window.submit_wbrs_call = (arg, path, output) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}


  $.ajax(
    url: '/escalations/api/v1/escalations/admin/tools/wbrs_call'
    method: 'POST'
    headers: headers
    data: {'user_arg': arg, 'path': path}

    success: (response) ->
      #json = $.parseJSON(response)
      if response.status == 'error'
        $(output).html("ERROR:" + response.message)
      else
        $(output).html(response.message)

    error: (response) ->
      $(output).html('An error occurred attempting to execute task')
  , this)


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


  $("#execute-task-button-1").click ->
    arg = $(".1-args").val();
    path = 'webcat1'
    output = '#output-1'

    window.submit_wbrs_call(arg, path, output)

  $("#execute-task-button-2").click ->
    arg = $(".2-args").val();
    path = 'webcat2'
    output = '#output-2'

    window.submit_wbrs_call(arg, path, output)

  $("#execute-task-button-3").click ->
    arg = $(".3-args").val();
    path = 'webcat3'
    output = '#output-3'

    window.submit_wbrs_call(arg, path, output)

  $("#execute-task-button-4").click ->
    arg = $(".4-args").val();
    path = 'webcat4'
    output = '#output-4'

    window.submit_wbrs_call(arg, path, output)

  $("#execute-task-button-5").click ->
    arg = $(".5-args").val();
    path = 'webcat5'
    output = '#output-5'

    window.submit_wbrs_call(arg, path, output)

  $("#execute-task-button-6").click ->
    arg = $(".6-args").val();
    path = 'webcat6'
    output = '#output-6'

    window.submit_wbrs_call(arg, path, output)

  $("#execute-task-button-7").click ->
    arg = $(".7-args").val();
    path = 'webcat7'
    output = '#output-7'

    window.submit_wbrs_call(arg, path, output)

  $("#execute-task-button-71").click ->
    arg = $(".71-args").val();
    path = 'webcat71'
    output = '#output-71'

    window.submit_wbrs_call(arg, path, output)

  $("#execute-task-button-8").click ->
    arg = $(".8-args").val();
    path = 'webrep8'
    output = '#output-8'

    window.submit_wbrs_call(arg, path, output)

  $("#execute-task-button-9").click ->
    arg = $(".9-args").val();
    path = 'webrep9'
    output = '#output-9'

    window.submit_wbrs_call(arg, path, output)

  $("#execute-task-button-10").click ->
    arg = $(".10-args").val();
    path = 'webrep10'
    output = '#output-10'

    window.submit_wbrs_call(arg, path, output)
