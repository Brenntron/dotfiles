window.populate_webrep_index_table = () ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep/disputes'
    method: 'GET'
    headers: headers
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

window.row_add_wlbl_button =(button_tag) ->
  wlbl_form = button_tag.form;
  data = {
    'dispute_entry_ids': [ wlbl_form.getElementsByClassName('dispute-entry-id')[0].value ]
    'trgt_list': wlbl_form.getElementsByClassName('adjust-wlbl-trgt_list-input')[0].value
    'note': wlbl_form.getElementsByClassName('adjust-wlbl-note-input')[0].value
  }
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep/disputes/wlbl'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    error: (response) ->
      debugger
  )

window.toolbar_add_wlbl_button =(button_tag) ->
  entry_ids = $('.dispute_check_box:checkbox:checked').map(() ->
    this.dataset['entryId']
  ).toArray()

  wlbl_form = button_tag.form
  data = {
    'dispute_entry_ids': entry_ids
    'trgt_list': wlbl_form.getElementsByClassName('adjust-wlbl-trgt_list-input')[0].value
    'note': wlbl_form.getElementsByClassName('adjust-wlbl-note-input')[0].value
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep/disputes/wlbl'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
  )


window.row_add_reptool_bl_button =(button_tag) ->
  reptool_bl_form = button_tag.form
  data = {
    'dispute_entry_ids': [ reptool_bl_form.getElementsByClassName('dispute-entry-id')[0].value ]
    'classifications': [ reptool_bl_form.getElementsByClassName('adjust-reptool-bl-classifications-input')[0].value ]
    'comment': reptool_bl_form.getElementsByClassName('adjust-reptool-bl-comment-input')[0].value
  }
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep/disputes/reptool_bl'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
  )

window.toolbar_add_reptool_bl_button =(button_tag) ->
  entry_ids = $('.dispute_check_box:checkbox:checked').map(() ->
    this.dataset['entryId']
  ).toArray()

  reptool_bl_form = button_tag.form
  data = {
    'dispute_entry_ids': entry_ids
    'classifications': [ reptool_bl_form.getElementsByClassName('adjust-reptool-bl-classifications-input')[0].value ]
    'comment': reptool_bl_form.getElementsByClassName('adjust-reptool-bl-comment-input')[0].value
  }
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep/disputes/reptool_bl'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
  )

$ ->
  $('#disputes_check_box').change ->
    $('.dispute_check_box').prop 'checked', @checked
    return
