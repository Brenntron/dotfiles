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

window.submit_reptool_call = (arg, path, output) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}


  $.ajax(
    url: '/escalations/api/v1/escalations/admin/tools/reptool_call'
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




window.submit_wbnp_report_destroy = (id)->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}


  $.ajax(
    url: '/escalations/api/v1/escalations/admin/tools/delete_wbnp_report'
    method: 'POST'
    headers: headers
    data: {'id': id}

    success: (response) ->
#json = $.parseJSON(response)
      if response.status == 'error'
        $('#wbnp_report_index_error').html("ERROR:" + response.message)
      else
        #$(output).html(response.message)
        window.location.reload()

    error: (response) ->
      $("#wbnp_report_index_error").html('An error occurred attempting to execute task')
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


window.submit_all_ticket_sync = (escalation_type)->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/admin/tools/sync_collection'
    method: 'POST'
    headers: headers
    data: {'all': true, 'escalation_type': escalation_type}

    success: (response) ->
      json = response

      if json.status == 'error'
        $('#output-1').html("ERROR:" + json.message)
      else
        $('#output-1').html(json.message)

    error: (response) ->
      $('#output-1').html('An error occurred attempting to execute task')
  , this)

window.submit_ticket_sync = (escalation_type, ids)->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/admin/tools/sync_collection'
    method: 'POST'
    headers: headers
    data: {'escalation_type': escalation_type, 'ids': ids}

    success: (response) ->
      json = response
      if json.status == 'error'
        $('#output-1').html("ERROR:" + json.message)
      else
        $('#output-1').html(json.message)

    error: (response) ->
      $('#output-1').html('An error occurred attempting to execute task')
  , this)

window.purge_mozprofiles =() ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  std_msg_ajax(
    method: 'POST'
    headers: headers
    url: "/escalations/api/v1/escalations/admin/tools/purge_mozprofiles"
    success: (response) ->
      std_msg_success("mozprofiles have been purged!", [response.message], reload: false)
    error: (response) ->
      std_msg_error("there was an error when attempting to purge mozprofiles.",[response.responseText], reload: false)
  , this)

window.purge_mozilla_corefiles =() ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  keep = $('input[id="purgeCore-checkbox"]').is(":checked")
  std_msg_ajax(
    method: 'POST'
    headers: headers
    url: "/escalations/api/v1/escalations/admin/tools/purge_mozilla_corefiles"
    data:{keep_one : keep}
    success: (response) ->
      std_msg_success("Cores have been purged!", [response.message], reload: false)
    error: (response) ->
      std_msg_error("there was an error when attempting to purge core files.",[response.responseText], reload: false)
  , this)

window.get_api_status = () ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  std_msg_ajax(
    method: 'GET'
    headers: headers
    url: '/escalations/api/v1/escalations/admin/tools/api_status_report'
    data:{}
    success: (response) ->
      $('.ajax-message-div').css('display','none')
      format_statuses(response)

    error: (response) ->
      $('.ajax-message-div').css('display','none')
      console.log response
  , this)

window.format_statuses = (data) ->
  { servers } = data
  container = document.getElementById('status_api_container')
  stat_table = document.createElement("table");
  stat_table.innerHTML =
    "<tr>
      <th>Server</th>
      <th>API</th>
      <th>Status</th>
    </tr>"
  for server, name of servers
    if data[server].is_healthy
      status_class = 'api-status-success'
    else
      status_class = 'api-status-fail'

    tr = document.createElement("tr");
    tr.innerHTML =
      "<td class = 'content-label-md'>
        #{server}
       </td>
       <td>
        #{name}
        </td>
       <td>
        <span class='#{status_class}'></span>
      </td>"
    stat_table.append(tr)
  container.append(stat_table)
#    console.log server, name
#    console.log data[server]
$ ->

  $("#sync-all-disputes").click ->
    window.submit_all_ticket_sync("Dispute")
  $("#sync-all-complaints").click ->
    window.submit_all_ticket_sync("Complaint")
  $("#sync-all-file-reps").click ->
    window.submit_all_ticket_sync("FileReputationDispute")

  $("#sync-disputes").click ->
    ids = $(".sync_dispute_field").val()
    window.submit_ticket_sync("Dispute", ids)

  $("#sync-complaints").click ->
    ids = $(".sync_complaint_field").val()
    window.submit_ticket_sync("Complaint", ids)

  $("#sync-file-disputes").click ->
    ids = $(".sync_filerep_field").val()
    window.submit_ticket_sync("FileReputationDispute", ids)



  $(".wbnp_delete_button").click ->

    id = $(this).data("id")  #<button data-id="123">delete</button>
    if window.confirm("are you sure")
      window.submit_wbnp_report_destroy(id)

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
####################################################
  $("#execute-reptool-button-1").click ->
    arg = $(".1-reptool-args").val();
    path = 'reptool1'
    output = '#reptool-output-1'

    window.submit_reptool_call(arg, path, output)

  $("#execute-reptool-button-2").click ->
    arg = $(".2-reptool-args").val();
    path = 'reptool2'
    output = '#reptool-output-2'

    window.submit_reptool_call(arg, path, output)

  $("#execute-reptool-button-3").click ->
    arg = $(".3-reptool-args").val();
    path = 'reptool3'
    output = '#reptool-output-3'

    window.submit_reptool_call(arg, path, output)

  $("#execute-reptool-button-4").click ->
    arg = $(".4-reptool-args").val();
    path = 'reptool4'
    output = '#reptool-output-4'

    window.submit_reptool_call(arg, path, output)