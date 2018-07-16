
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
      name: $('#new_named_search').find('input[id="name-input"]').val()
      email: $('#new_named_search').find('input[id="email-input"]').val()
      company_name: $('#new_named_search').find('input[id="company-input"]').val()
    }
    dispute_entries: {
      ip_or_uri: $('#new_named_search').find('input[id="dispute-input"]').val()
      suggested_disposition: $('#new_named_search').find('input[id="disposition-input"]').val()
    }
    search_type: 'advanced'
    search_name: $('#new_named_search').find('input[name="search_name"]').val()
    case_id: $('#new_named_search').find('input[id="caseid-input"]').val()
    org_domain: $('#new_named_search').find('input[id="domain-input"]').val()
    case_owner_username: $('#new_named_search').find('input[id="owner-input"]').val()
    status: $('#new_named_search').find('input[id="status-input"]').val()
    priority: $('#new_named_search').find('input[id="priority-input"]').val()
    resolution: $('#new_named_search').find('input[id="resolution-input"]').val()
    submitter_type: $('#new_named_search').find('input[id="submitter-input"]').val()
  }
  window.populate_webrep_index_table(data)

window.named_webrep_index_table = (search_name) ->
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

$ ->
  $('#disputes_check_box').change ->
    $('.dispute_check_box').prop 'checked', @checked
    return
