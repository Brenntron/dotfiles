
window.populate_webrep_index_table = (data = {}) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep/disputes'
    method: 'GET'
    headers: headers
    data: data
    success: (response) ->

      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        alert(json.error)
      else
        datatable = $('#disputes-index').DataTable()
        datatable.clear();
        datatable.rows.add(json.data);
        datatable.draw();

    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
      #$("#alert_message").addClass('alert alert-danger alert-dismissable').append(notice_html)
      #$("#create_research_submit_wait").addClass('hidden').hide()
      #$("#create_research_submit").show()
  , this)

window.advanced_webrep_index_table = () ->
  debugger
  data = {
    customer: {
      name: $('#new_named_search').find('input[id="contact-name-cb"]').val()
      email: $('#new_named_search').find('input[id="contact-email-cb"]').val()
      company_name: $('#new_named_search').find('input[id="company-cb"]').val()
    }
    dispute_entries: {
      ip_or_uri: $('#new_named_search').find('input[name="ip_or_uri"]').val()
      suggested_disposition: $('#new_named_search').find('input[id="disposition-cb"]').val()
    }
    search_type: 'advanced'
    search_name: $('#new_named_search').find('input[name="search_name"]').val()
    case_id: $('#new_named_search').find('input[id="caseid-cb"]').val()
    username: $('#new_named_search').find('input[name="username"]').val()
    status: $('#new_named_search').find('input[name="status"]').val()
    priority: $('#new_named_search').find('input[id="priority-cb"]').val()
    resolution: $('#new_named_search').find('input[id="resolution-cb"]').val()
  }
  window.populate_webrep_index_table(data)

window.named_webrep_index_table = (search_name) ->
  debugger
  data = {
    search_type: 'standard'
    search_name: search_name
  }
  window.populate_webrep_index_table(data)


window.popup_response_error =(response, prefix) ->
  if response.responseJSON == undefined
    response_lines = response.responseText.split("\n")
    if 2 < response_lines.length
      errormsg = response_lines[0] + "\n" + response_lines[1]
    else
      errormsg = response.responseText
  else if response.responseJSON.error != undefined
    errormsg = response.responseJSON.error
  else
    errormsg = response.responseText

  alert(prefix + "\n" + errormsg)

window.row_adust_wlbl_button =(button_tag) ->
  wlbl_form = button_tag.form;
  data = {
    'dispute_entry_ids': [ wlbl_form.getElementsByClassName('dispute-entry-id')[0].value ]
    'trgt_list': wlbl_form.getElementsByClassName('trgt_list-input')[0].value
    'note': wlbl_form.getElementsByClassName('note-input')[0].value
  }
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep/disputes/wlbl'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error adjusting WL/BL')
  )

window.toolbar_adust_wlbl_button =(button_tag) ->
  entry_ids = $('.dispute_check_box:checkbox:checked').map(() ->
    this.dataset['entryId']
  ).toArray()

  wlbl_form = button_tag.form
  data = {
    'dispute_entry_ids': entry_ids
    'trgt_list': wlbl_form.getElementsByClassName('trgt_list-input')[0].value
    'note': wlbl_form.getElementsByClassName('note-input')[0].value
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep/disputes/wlbl'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error adjusting WL/BL')
  )


window.row_adust_reptool_bl_button =(button_tag) ->
  reptool_bl_form = button_tag.form
  data = {
    'action': reptool_bl_form.getElementsByClassName('action-input')[0].value
    'dispute_entry_ids': [ reptool_bl_form.getElementsByClassName('dispute-entry-id')[0].value ]
    'classifications': [ reptool_bl_form.getElementsByClassName('classifications-input')[0].value ]
    'comment': reptool_bl_form.getElementsByClassName('comment-input')[0].value
  }
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep/disputes/reptool_bl'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error adjusting WL/BL')
  )

window.toolbar_adjust_reptool_bl_button =(button_tag) ->
  entry_ids = $('.dispute_check_box:checkbox:checked').map(() ->
    this.dataset['entryId']
  ).toArray()

  reptool_bl_form = button_tag.form
  data = {
    'action': reptool_bl_form.getElementsByClassName('action-input')[0].value
    'dispute_entry_ids': entry_ids
    'classifications': [ reptool_bl_form.getElementsByClassName('classifications-input')[0].value ]
    'comment': reptool_bl_form.getElementsByClassName('comment-input')[0].value
  }
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep/disputes/reptool_bl'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error adjusting WL/BL')
  )

window.toolbar_index_edit_status = (box_names) ->
  entry_ids = $('.dispute_check_box:checkbox:checked').map(() ->
    # this.dataset['entryId']
    this.value
  ).toArray()

  new_status = $('index_target_status')

  data = {
    'dispute_entry_ids': entry_ids,
    'new_status': new_status
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep/disputes/edit_status'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error editing ticket status')
  )

window.toolbar_index_change_assignee = (button_tag) ->

  entry_ids = $('.dispute_check_box:checkbox:checked').map(() ->
    # this.dataset['entryId']
    this.value
  ).toArray()

  new_assignee = $('index_target_assignee')

  data = {
    'dispute_entry_ids': entry_ids,
    'new_assignee': new_assignee
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep/disputes/change_assignee'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error changing assignee')
  )

window.toolbar_index_mark_duplicate = (box_names) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep/disputes/mark_duplicate'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error marking duplicate')
  )

window.determine_checked = (box_names) ->
  box_flag = ($('.'+box_names+':checked').length > 0)
  unless box_flag
    alert('check something first')
  console.log 'returning: ' + box_flag
  return box_flag

$ ->
  $('#disputes_check_box').change ->
    $('.dispute_check_box').prop 'checked', @checked
    return

  # Edit Ticket: Edit Ticket Status
  $('#index_ticket_status').click ->
    if (determine_checked('dispute_check_box'))
      console.log 'do the needful'
    else
      do_not = "show the tab"

  # Edit Ticket: Change Assignee
  $('#index_change_assign').click ->
    if (determine_checked('dispute_check_box'))
      console.log 'do the needful'
    else
      do_not = "show the tab"
