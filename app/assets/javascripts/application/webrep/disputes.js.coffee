window.select_or_deselect_all = (dispute_id)->


  $('.dispute-entry-checkbox_' + dispute_id).prop('checked', $('#' + dispute_id).prop('checked'))

window.populate_webrep_index_table = (data = {}) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes'
    method: 'GET'
    headers: headers
    data: data
    data_json: JSON.stringify(data)
    success: (response) ->
      $('#disputes-index-export-data-input').val(this.data_json)

      json = $.parseJSON(response)

      if json.data.length == 0
        std_msg_error("No tickets matching filter or search.","")

      if json.error
        std_msg_error("An error occured while retrieving data.","")
      else
        $('#dispute-index-title').text(json['title'])
        datatable = $('#disputes-index').DataTable()
        datatable.clear();
        datatable.rows.add(json.data);
        datatable.draw();

        if undefined != json.search_name
          $('#saved-search-tbody').append(named_search_tag(json.search_name, json.search_id))

    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
      std_msg_error("An error occured while retrieving data.","")
  , this)

window.advanced_webrep_index_table = () ->
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
    submitted_older: $('#new_named_search').find('input[id="submitted-older-input"]').val()
    submitted_newer: $('#new_named_search').find('input[id="submitted-newer-input"]').val()
    age_older: $('#new_named_search').find('input[id="age-older-input"]').val()
    age_newer: $('#new_named_search').find('input[id="age-newer-input"]').val()
    modified_older: $('#new_named_search').find('input[id="modified-older-input"]').val()
    modified_newer: $('#new_named_search').find('input[id="modified-newer-input"]').val()
  }
  window.populate_webrep_index_table(data)

window.standard_webrep_index_table = (search_name) ->
  data = {
    search_type: 'standard'
    search_name: search_name
  }
  window.populate_webrep_index_table(data)

window.named_webrep_index_table = (search_name) ->
  data = {
    search_type: 'named'
    search_name: search_name
  }
  window.populate_webrep_index_table(data)

window.call_contains_search = (search_form) ->
  data = {
    search_type: 'contains'
    value: search_form.querySelector('input.search-box').value
  }
  window.populate_webrep_index_table(data)

window.delete_disputes_named_search = (close_button, search_name) ->
  std_msg_ajax(
    method: 'DELETE'
    url: "/escalations/api/v1/escalations/webrep/disputes/searches/#{search_name}"
    data: {}
    error_prefix: 'Error deleting saved search.'
    failure_reload: false
    tr_tag: close_button.closest('tr')
    success: (response) ->
      this.tr_tag.remove();
  )




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

window.row_adjust_wlbl_button =(button_tag) ->
  list_types = $('.wl-bl-list-inline:checkbox:checked').map(() ->
    this.value
  ).toArray()
  wlbl_form = button_tag.form;
  data = {
    'dispute_entry_ids': [ wlbl_form.getElementsByClassName('dispute-entry-id')[0].value ]
    'trgt_list': list_types
    'note': wlbl_form.getElementsByClassName('note-input')[0].value
  }

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/entry_wlbl'
    method: 'POST'
    data: data
    error_prefix: 'Error adjusting WL/BL.'
  )

window.row_research_adjust_wlbl_button =(button_tag) ->
  list_types = $('.wl-bl-list-inline:checkbox:checked').map(() ->
    this.value
  ).toArray()
  wlbl_form = button_tag.form;

  data = {
    'urls': [ wlbl_form.getElementsByClassName('dispute-entry-content')[0].value ]
    'trgt_list': list_types
    'note': wlbl_form.getElementsByClassName('note-input')[0].value
  }

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/uri_wlbl'
    method: 'POST'
    data: data
    error_prefix: 'Error adjusting WL/BL.'
    success_reload: true
  )


window.toolbar_adust_wlbl_button =(button_tag) ->
  entry_ids = $('.dispute_check_box:checkbox:checked').map(() ->
    this.dataset['entryId']
  ).toArray()
  list_types = $('.wl-bl-list-inline:checkbox:checked').map(() ->
    this.value
  ).toArray()

  wlbl_form = button_tag.form
  data = {
    'dispute_entry_ids': entry_ids
    'trgt_list': list_types
    'note': wlbl_form.getElementsByClassName('adjust-wlbl-input')[0].value
  }

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/entry_wlbl'
    method: 'POST'
    data: data
    error_prefix: 'Error adjusting WL/BL.'
    success_reload: true
  )

window.toolbar_research_adjust_wlbl_button =(button_tag) ->
  checked_url = $('.dispute_check_box:checked')[0]
  entry_row = $(checked_url).parents('.research-table-row')[0]
  url = $(entry_row).find('.entry-data-content').text()
  list_types = $('.wl-bl-list-inline:checkbox:checked').map(() ->
    this.value
  ).toArray()

  wlbl_form = button_tag.form

  data = {
    'urls': [ url ]
    'trgt_list': list_types
    'note': wlbl_form.getElementsByClassName('adjust-wlbl-input')[0].value
  }

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/uri_wlbl'
    method: 'POST'
    data: data
    error_prefix: 'Error adjusting WL/BL.'
    success_reload: true
  )


window.index_adust_wlbl_button =(button_tag) ->
  dispute_ids = $('.dispute_check_box:checkbox:checked').map(() ->
    this.value
  ).toArray()
  list_types = $('.wl-bl-list-inline:checkbox:checked').map(() ->
    this.value
  ).toArray()

  wlbl_form = button_tag.form
  data = {
    'dispute_ids': dispute_ids
    'trgt_list': list_types
    'note': wlbl_form.getElementsByClassName('adjust-wlbl-input')[0].value
  }

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/ticket_wlbl'
    method: 'POST'
    data: data
    error_prefix: 'Error adjusting WL/BL.'
  )

window.save_dispute = () ->
  data = {
    'priority': $('#dispute-priority-select').val()
    'customer_name': $('#dispute-customer-name-input').val()
    'customer_email': $('#dispute-customer-email-input').val()
    'status': $('#status').val()
  }

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/' + $('#dispute_id').text()
    method: 'PUT'
    data: data
    error_prefix: 'Unable to update dispute.'
    success_reload: true
  )

# Populating the in line Adjust Reptool button for research page and research tab
window.inline_load_reptool_button =(button_tag) ->
  #debugger
  adjust_form = button_tag.parentElement.getElementsByClassName('adjust-reptool-form')[0]
  submit_button = adjust_form.getElementsByClassName('dropdown-submit-button')
  #$(submit_button).attr("disabled", false)

  #button_tag.parentElement.getElementsByClassName('adjust-reptool-form')[0].getElementsByClassName('dropdown-submit-button')

  #dropdown = $('#reptool_adjust_entries').parent()

  show_content = $(adjust_form).find('.entry-dispute-name')
  show_rep_class = $(adjust_form).find('.entry-reptool-class')
  show_rep_exp = $(adjust_form).find('.entry-reptool-expiration')
  action_input = $(adjust_form).find('.action-input')
  classifications_input = $(adjust_form).find('.classifications-input')
  comment_input = $(adjust_form).find('.comment-input')
  data = {
# Send entry content to reptool
    'entry' : adjust_form.getElementsByClassName('dispute-entry-content')[0].value
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/reptool_get_info_for_form'
    method: 'GET'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      response = JSON.parse(response)

      show_content.text(adjust_form.getElementsByClassName('dispute-entry-content')[0].value)
      show_rep_class.text(response.classification)
      show_rep_exp.text(response.expiration)
      action_input.val(response.status)
      classifications_input.val(response.classification)
      comment_input.val(response.comment)
      $(submit_button).attr('disabled', false)
#          window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error retrieving Reptool Data')
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
    url: '/escalations/api/v1/escalations/webrep/disputes/reptool_bl'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error adjusting WL/BL')
  )

window.row_adust_reptool_bl_button_research =(button_tag) ->
  reptool_bl_form = button_tag.form

  data = {
    'action': reptool_bl_form.getElementsByClassName('action-input')[0].value
    'entries': [ reptool_bl_form.getElementsByClassName('dispute-entry-content')[0].value ]
    'classifications': [ reptool_bl_form.getElementsByClassName('classifications-input')[0].value ]
    'comment': reptool_bl_form.getElementsByClassName('comment-input')[0].value
  }
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/reptool_bl'
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
    url: '/escalations/api/v1/escalations/webrep/disputes/reptool_bl'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error adjusting WL/BL')
  )

window.toolbar_adjust_reptool_bl_button_research =(button_tag) ->
  checked_url = $('.dispute_check_box:checked')[0]
  entry_row = $(checked_url).parents('.research-table-row')[0]
  url = $(entry_row).find('.entry-data-content').text()

  reptool_bl_form = button_tag.form
  data = {
    'action': reptool_bl_form.getElementsByClassName('action-input')[0].value
    'entries': [ url ]
    'classifications': [ reptool_bl_form.getElementsByClassName('classifications-input')[0].value ]
    'comment': reptool_bl_form.getElementsByClassName('comment-input')[0].value
  }
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/reptool_bl'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error adjusting WL/BL')
  )





window.toolbar_index_edit_status = () ->
  statusName = $('input[name=entry-status]:checked').attr('id')
  
  data = {}
  
  entry_ids = $('.dispute-entry-checkbox:checked').map(() ->
    data[this.id] = [{
      id: this.id
      field: "status"
      new: statusName
    }]

    if statusName == "RESOLVED_CLOSED"
      data[this.id].push({
        id: this.id
        field: "resolution"
        new: $('input[name=entry-resolution]:checked').attr('id')
      })

      data[this.id].push({
        id: this.id
        field: "resolution_comment"
        new: $('#entry-status-comment').val()
      })

  )

  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/webrep/disputes/entries/field_data"
    data: { field_data: data }
    success_reload: true
    error_prefix: 'Error updating data.'
  )

window.show_page_edit_status = () ->
  statusName = $('input[name=dispute-status]:checked').attr('id')
  comment = $('#dispute-status-comment').val()
  dispute_id = $('#dispute_id').text()

  if statusName == "RESOLVED_CLOSED"
    resolution = $('input[name=dispute-resolution]:checked').attr('id')

  data = {
    dispute_ids: [ dispute_id ]
    status: statusName
    comment: comment
  }

  if resolution
    data.resolution = resolution
    data.comment = $('#dispute-resolution-comment').val()

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/set_disputes_status'
    method: 'POST'
    data: data
    error_prefix: 'Unable to update dispute.'
    success_reload: true
  )

window.toolbar_index_change_assignee = () ->

  entry_ids = $('.dispute_check_box:checkbox:checked').map(() ->
# this.dataset['entryId']
    Number(this.value)
  ).toArray()

  new_assignee = $('#index_target_assignee option:selected').val()
  data = {
    'dispute_ids': entry_ids,
    'new_assignee': new_assignee
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/change_assignee'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error changing assignee')
  )

window.toolbar_show_change_assignee = () ->
  single_id = $('#dispute_id').text()
  entry_ids = [single_id]

  new_assignee = $('#index_target_assignee option:selected').val()
  data = {
    'dispute_ids': entry_ids,
    'new_assignee': new_assignee
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/change_assignee'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error changing assignee')
  )

window.related_disputes = () ->
  entry_ids = $('.dispute_check_box:checkbox:checked').map(() ->
    Number(this.value)
  ).toArray()

  original_dispute_id = $('.dispute-id').val()

  data = {
    'original_dispute_id': original_dispute_id
    'relating_dispute_ids': entry_ids
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/related_disputes'
    method: 'PATCH'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error setting related dispute.')
  )

window.toolbar_unassign_dispute = () ->
  single_id = $('#dispute_id').text()
  entry_ids = [single_id]

  data = {
    'dispute_ids': entry_ids
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/unassign_all'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error removing assignee')
  )

window.toolbar_index_mark_duplicate = (box_names) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/mark_duplicate'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error marking duplicate')
  )


window.add_dispute_entry = () ->
  $('#loader-modal').modal({
    backdrop: 'static',
    keyboard: false
  })
  data = {
    'uri': $('#add_dispute_entry').val(),
    'dispute_id': $('#dispute_id').text(),
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/new_adhoc_entry'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error adding entry.')
  )

window.add_related_case_id= ()->
  id = $('#dispute_id').text()
  invalid_id = false
  related_id = $('.dispute-id').val().split(",")
  data = {
    'relating_dispute_ids': related_id
  }
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  for i in related_id
    if(isNaN(i)||i.length < 1)
      invalid_id = true
  if related_id[0].length < 1
    std_msg_error("Invalid ID",["You must enter a valid ID to relate."])
  else if(invalid_id)
    std_msg_error("Invalid ID",["One of your IDs is NOT a valid ID number."])
  else
    std_msg_ajax(
      method: 'PATCH'
      url: '/escalations/api/v1/escalations/webrep/disputes/' + id + '/relating_disputes'
      data: data
      success_reload: true
      error_prefix: 'Error marking relationship.'
    )

window.determine_checked = (box_names) ->
  box_flag = ($('.'+box_names+':checked').length > 0)
  unless box_flag
    alert('check something first')
  console.log 'returning: ' + box_flag
  return box_flag


window.take_dispute = (dispute_id) ->
  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/webrep/disputes/take_dispute/" + dispute_id
    data: {}
    dispute_id: dispute_id
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      $('.take-dispute-' + dispute_id).replaceWith("<button class='return-ticket-button return-ticket-#{dispute_id}' title='Assign this ticket to me' onclick='return_dispute(#{dispute_id});'></button>")
      $('#owner_' + dispute_id).text(response.username)
      $('#status_' + dispute_id).text("Assigned")
  )


window.take_disputes = () ->
  dispute_ids = $('.dispute_check_box:checkbox:checked').map(() ->
    this.dataset['entryId']
    this.value
  ).toArray()

  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/webrep/disputes/take_disputes"
    data: { dispute_ids: dispute_ids }
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      for dispute_id in response.dispute_ids
        $('#owner_' + dispute_id).text(response.username)
        $('#status_' + dispute_id).text("Assigned")
  )



window.take_single_dispute = (id) ->
  dispute_ids = [ id ]

  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/webrep/disputes/take_disputes"
    data: { dispute_ids: dispute_ids }
    error_prefix: 'Error updating ticket.'
    success_reload: true
  )

window.return_dispute = (dispute_id) ->
  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/webrep/disputes/return_dispute/" + dispute_id
    data: {}
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      $('.return-ticket-' + dispute_id).replaceWith("<button class='take-ticket-button take-dispute-#{dispute_id}' title='Assign this ticket to me' onclick='take_dispute(#{dispute_id});'></button>")
      $('#owner_' + response.dispute_id).text('Unassigned')
      $('#status_' + response.dispute_id).text('NEW')

  )


#window.dispute_entry_status = (id, status) ->
#  std_msg_ajax(
#    method: 'PATCH'
#    url: '/escalations/api/v1/escalations/webrep/disputes/entries/' + id + '/status'
#    data: { status: status }
#    error_prefix: 'Error updating status.'
#  )


window.save_dispute_entries = () ->

  data = {}
  $('#disputes-research-table').find('tr.research-table-row').each(() ->
    result = {}
    fielddata = $(this).find('.dual-edit-field').map(() ->

      new_value = switch (this.dataset.field)
        when 'status' then $(this).find("input[name='entry-status']:checked").attr('id')
        else $(this).find('.table-entry-input')[0].value.trim()

      old_value = $(this).find('.entry-data')[0].innerText.trim()

      if new_value == undefined
        new_value = old_value

      data[this.dataset.id] = [{
        id: this.dataset.id
        field: this.dataset.field
        old: old_value
        new: new_value
      }]

      if new_value == "RESOLVED_CLOSED" && (new_value != old_value)
        data[this.dataset.id].push(
          id: this.dataset.id
          field: "resolution"
          new: $('input[name=entry-resolution]:checked').attr('id')
        )

        data[this.dataset.id].push({
          id: this.dataset.id
          field: "resolution_comment"
          new: $(this).find("textarea[name='resolution-comment']")[0].value
        })

    ).toArray().filter((field_data) ->
      field_data.old != field_data.new
    )

    if 0 < fielddata.length
      data[this.dataset.entryId] = fielddata

  )

  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/webrep/disputes/entries/field_data"
    data: { field_data: data }
    success_reload: true
    error_prefix: 'Error updating data.'
  )


window.show_set_related_dispute = () ->
  $('#set-related-dispute-div').show()

window.set_related_dispute = (form_tag) ->
  related_dispute_id = $(form_tag).find(".dispute-id").val()
  std_msg_ajax(
    method: 'POST'
    url: '/escalations/api/v1/escalations/webrep/disputes/' + form_tag.dataset.disputeId + '/related_disputes'
    data: { related_dispute_id: related_dispute_id }
    success_reload: true
    error_prefix: 'Error marking relationship.'
  )

window.set_relating_disputes = (form_tag) ->
  related_dispute_id = $(form_tag).find(".dispute-id").val()
  dispute_ids = $('.dispute_check_box:checkbox:checked').map(() ->
    this.value
  ).toArray()
  std_msg_ajax(
    method: 'PATCH'
    url: '/escalations/api/v1/escalations/webrep/disputes/' + related_dispute_id + '/relating_disputes'
    data: { relating_dispute_ids: dispute_ids }
    success_reload: true
    error_prefix: 'Error marking relationship.'
  )

window.show_set_duplicate_dispute = () ->
  $('#set-duplicate-dispute-div').show()

window.set_duplicate_dispute = (form_tag) ->
  duplicate_dispute_id = $(form_tag).find(".dispute-id").val()
  std_msg_ajax(
    method: 'POST'
    url: '/escalations/api/v1/escalations/webrep/disputes/' + form_tag.dataset.disputeId + '/duplicate_disputes'
    data: { duplicate_dispute_id: duplicate_dispute_id }
    success_reload: true
    error_prefix: 'Error marking duplicate relationship.'
  )



$ ->

  $('.change_ticket_status_button').click ->
    status = ""
    resolution = ""
    comment = ""
    checkboxes = $('#disputes-index').find('.dispute_check_box')
    checked_disputes = []
    $(checkboxes).each ->
      if $(this).is(':checked')
        dispute_id = $(this).val()
        checked_disputes.push(dispute_id)

    status = $('#index-edit-ticket-status-dropdown').find('.ticket-status-radio:checked').val()
    if status == 'RESOLVED_CLOSED'
      resolution = $('#index-edit-ticket-status-dropdown').find('.ticket-resolution-radio:checked').val()
      comment = $('.resolution-comment-wrapper').find('.ticket-status-comment').val()
    else
      comment = $('.non-resolution-submit-wrapper').find('.ticket-status-comment').val()


    data = {
      status: status,
      resolution: resolution,
      comment: comment,
      dispute_ids: checked_disputes.toString()
    }

    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/set_disputes_status'
      method: 'POST'
      headers: headers
      data: data
      dataType: 'json'
      success: (response) ->
        response = JSON.parse(response)
        if response.status == "success"
          window.location.reload()
      error: (response) ->
        popup_response_error(response, 'Error Updating Status')
        window.location.reload()

    )


  $('#disputes_check_box').change ->
    $('.dispute_check_box').prop 'checked', @checked
    return

  # Edit Ticket: Edit Ticket Status
  $('#index_ticket_status').click ->
    dropdown = $('#index-edit-ticket-status-dropdown').parent()
    if ($('.dispute_check_box:checked').length > 0)
# Select Status
      $('.ticket-status-radio-label').click ->
        radio_button = $(this).prev('.ticket-status-radio')
        $(radio_button[0]).trigger('click')
        if $(radio_button).attr('id') == 'RESOLVED_CLOSED'
          $('#index-ticket-resolution-submenu').show()
          stat_comment = $('#ticket-non-res-submit').find('.ticket-status-comment')
          $('#ticket-non-res-submit').hide()
          $(stat_comment).val('')
        else
          $('#ticket-non-res-submit').show()
          res_comment = $('.resolution-comment-wrapper').find('.ticket-status-comment')
          $('.ticket-resolution-radio').prop('checked', false)
          $('#index-ticket-resolution-submenu').hide()
          $(res_comment[0]).val('')

      $('.ticket-status-radio').click ->
        all_stat_radios = $('#index-edit-ticket-status-dropdown').find('.status-radio-wrapper')
        if $(this).is(':checked')
          wrapper = $(this).parent()
          $(all_stat_radios).removeClass('selected')
          $(wrapper).addClass('selected')
        if $(this).attr('id') == 'RESOLVED_CLOSED'
          $('#index-ticket-resolution-submenu').show()
          stat_comment = $('#ticket-non-res-submit').find('.ticket-status-comment')
          $('#ticket-non-res-submit').hide()
          $(stat_comment).val('')
        else
          $('#ticket-non-res-submit').show()
          res_comment = $('.resolution-comment-wrapper').find('.ticket-status-comment')
          $('.ticket-resolution-radio').prop('checked', false)
          $('#index-ticket-resolution-submenu').hide()
          $(res_comment[0]).val('')
    else
      $(dropdown).removeClass('open')
      alert ('No rows selected')

  # Edit Entry: Edit Entry Status
  $('#index-entry-status-button').click ->
    dropdown = $('#index-edit-entry-status-dropdown').parent()
    if ($('.dispute-entry-checkbox:checked').length > 0)

      $('.entry-status-radio-label').click ->
        radio_button = $(this).prev('.entry-status-radio')
        $(radio_button[0]).trigger('click')
        if $(radio_button).attr('id') == 'RESOLVED_CLOSED'
          $('#index-entry-resolution-submenu').show()
          stat_comment = $('#entry-non-res-submit').find('.entry-status-comment')
          $('#entry-non-res-submit').hide()
          $(stat_comment).val('')
        else
          $('#entry-non-res-submit').show()
          res_comment = $('#index-entry-resolution-submenu').find('.entry-status-comment')
          $('.entry-resolution-radio').prop('checked', false)
          $('#index-entry-resolution-submenu').hide()
          $(res_comment).val('')

      $('.entry-status-radio').click ->
        all_stat_radios = $('#index-edit-entry-status-dropdown').find('.status-radio-wrapper')
        if $(this).is(':checked')
          wrapper = $(this).parent()
          $(all_stat_radios).removeClass('selected')
          $(wrapper).addClass('selected')
        if $(this).attr('id') == 'RESOLVED_CLOSED'
          $('#index-entry-resolution-submenu').show()
          stat_comment = $('#entry-non-res-submit').find('.entry-status-comment')
          $('#entry-non-res-submit').hide()
          $(stat_comment).val('')
        else
          $('#entry-non-res-submit').show()
          res_comment = $('#index-entry-resolution-submenu').find('.entry-status-comment')
          $('.entry-resolution-radio').prop('checked', false)
          $('#index-entry-resolution-submenu').hide()
          $(res_comment).val('')
    else
      alert ('No rows selected')
      $(dropdown).removeClass('open')
      return false


  # Create index table
  dispute_table = $('#disputes-index').DataTable(
    order: [ [
      9
      'desc'
    ] ]
    dom: '<"datatable-top-tools"lf>t<ip>'
    columnDefs: [
      {
        targets: [
          0
          1
        ]
        orderable: false
        searchable: false
      }
      {
        targets: [ 0 ]
        className: 'expandable-row-column'
      }
      {
        targets: [ 3 ]
        className: 'id-col'
      }
      {
        targets: [ 4 ]
        className: 'state-col'
      }
      {
        targets: [
          2
          6
        ]
        className: 'text-center'
      }
      {
        targets: [ 8 ]
        className: 'alt-col'
      }
    ]
    columns: [
      {
        data: null
        defaultContent: '<button class="expand-row-button-inline"></button>'
      }
      {
        data: 'case_number'

        render: (data) ->

          '<input type="checkbox" name="cbox" class="dispute_check_box" id="cbox' + data + '" value="' + data + '" />'

      }
      {
        data: 'priority'
        render: (data) ->
          '<span class="bug-priority p-' + data + '"></span>'

      }
      { data: 'case_link' }
      { data: 'status' }
      {
        data: 'dispute_resolution'
      }
       {
        data: 'submission_type'
        render: (data) ->
          '<span class="dispute-submission-type dispute-' + data  + '"></span>'
      }
      { data: 'd_entry_preview' }
      { data: 'assigned_to' }
      { data: 'case_opened_at' }
      { data: 'case_age' }
      { data: 'source' }
      { data: 'submitter_type'}
      { data: 'submitter_org' }
      { data: 'submitter_domain' }
      { data: 'submitter_name' }
      { data: 'submitter_email' }


    ])

  format = (dispute) ->
    table_head = '<table class="table dispute-entry-table">' + '<thead>' + '<tr>' + '<th><input type="checkbox" onclick="select_or_deselect_all(' + dispute.id + ')" id=' + dispute.id + ' /></th>' + '<th class="entry-col-content">Dispute Entry</th>' + '<th class="entry-col-status">Dispute Entry Status</th>' + '<th class="entry-col-status">Dispute Entry Resolution</th>' + '<th class="entry-col-disp">Suggested Disposition</th>' + '<th class="entry-col-cat">Category</th>' + '<th class="entry-col-wbrs-score">WBRS Score</th>' + '<th class="entry-col-wbrs-hits">WBRS Total Rule Hits</th>' + '<th class="entry-col-wbrs-rules">WBRS Rules</th>' + '<th class="entry-col-sbrs-score">SBRS Score</th>' + '<th class="entry-col-sbrs-hits">SBRS Total Rule Hits</th>' + '<th class="entry-col-sbrs-rules">SBRS Rules</th>' + '</tr>' + '</thead>' + '<tbody>'
    entry = dispute.dispute_entries
    missing_data = '<span class="missing-data">Missing Data</span>'
    entry_rows = []
    $(entry).each ->
      entry_content = ''
      if this.entry.ip_address != null
        entry_content = this.entry.ip_address
      else if this.entry.uri != null
        entry_content = this.entry.uri
      else
        entry_content = missing_data

      category = ''
      if this.entry.primary_category != null
        category = this.entry.primary_category
      else
        category = missing_data
      status = ''
      if this.entry.status != null
        status = this.entry.status
      else
        status = missing_data
      resolution = ''
      if this.entry.resolution != null
        resolution = this.entry.resolution
      else
        resolution = missing_data
      resolution_comment = ''
      if this.entry.resolution_comment != null
        resolution_comment = this.entry.resolution_comment
      else
        resolution_comment = ''
      suggested_disposition = ''
      if this.entry.suggested_disposition != null
        suggested_disposition = this.entry.suggested_disposition
      else
        suggested_disposition = missing_data
      if this.entry.is_important == true
        important = 'entry-important-flag'
      else
        important = ''
      dispute_entry_id = this.entry.id
      if this.entry.wbrs_score != null
        wbrs_score = this.entry.wbrs_score
      else wbrs_score = missing_data
      if this.entry.sbrs_score != null
        sbrs_score = this.entry.sbrs_score
      else sbrs_score = missing_data
      entry_row = '<tr>' + '<td><input type="checkbox" class="dispute-entry-checkbox dispute-entry-checkbox_' + dispute.id + '" id= ' + dispute_entry_id + ' ></td>' + '<td class="entry-col-content ' + important + '">' + entry_content + '</td>' +
        '<td class="entry-col-status">' + status + '</td>' +
        '<td class="entry-col-res esc-tooltipped" title="' + resolution_comment + '">' + resolution + '</td>' +
        '<td class="entry-col-disp">' + suggested_disposition + '</td>' +
        '<td class="entry-col-cat">' + category + '</td>' +
        '<td class="entry-col-wbrs-score">' + wbrs_score + '</td>' +
        '<td class="entry-col-wbrs-hits">' +  this.wbrs_rule_hits.length + '</td>' +
        '<td class="entry-col-wbrs-rules">' + this.wbrs_rule_hits.join(', ') + '</td>' +
        '<td class="entry-col-sbrs-score">' + sbrs_score + '</td>' +
        '<td class="entry-col-sbrs-hits">' + this.sbrs_rule_hits.length + '</td>' +
        '<td class="entry-col-sbrs-rules">' + this.sbrs_rule_hits.join(', ') + '</td>'
      entry_rows.push entry_row
      return
    # `d` is the original data object for the row
    table_head + entry_rows.join('') + '</tbody></table>'

  if $('#disputes-index').length
    standard_webrep_index_table('open')
  $('#disputes-index tbody').on 'click', 'td.expandable-row-column', ->
    tr = $(this).closest('tr')
    row = dispute_table.row(tr)
    if row.child.isShown()
# This row is already open - close it
      row.child.hide()
      tr.removeClass 'shown'
    else
# Open this row
      row.child(format(row.data())).show()
      tr.addClass 'shown'
      td = $(tr).next('tr').find('td:first')
      $(td).addClass 'dispute-entry-table-wrapper'
      # Check to see which columns should be displayed
      $('.toggle-vis-nested').each ->
        checkbox_trigger = $(this).attr('data-column')
        checkbox = $(this).find('input')
        if $(checkbox).prop('checked')
          $('.dispute-entry-table td, .dispute-entry-table th').each ->
            if $(this).hasClass(checkbox_trigger)
              $(this).show()
            return
        else if $(checkbox).prop('checked') == false
          $('.dispute-entry-table td, .dispute-entry-table th').each ->
            if $(this).hasClass(checkbox_trigger)
              $(this).hide()
            return
        return
    return

  # Expand all rows via toolbar button
  $('#expand-all-index-rows').click ->
    td = $('#disputes-index').find('td.expandable-row-column')
    $(td).each ->
      tr = $(this).closest('tr')
      row = dispute_table.row(tr)
      unless row.child.isShown()
        row.child(format(row.data())).show()
        tr.addClass 'shown'
        td = $(tr).next('tr').find('td:first')
        $(td).addClass 'dispute-entry-table-wrapper'
        # Check to see which columns should be displayed
        $('.toggle-vis-nested').each ->
          checkbox_trigger = $(this).attr('data-column')
          checkbox = $(this).find('input')
          if $(checkbox).prop('checked')
            $('.dispute-entry-table td, .dispute-entry-table th').each ->
              if $(this).hasClass(checkbox_trigger)
                $(this).show()
              return
          else if $(checkbox).prop('checked') == false
            $('.dispute-entry-table td, .dispute-entry-table th').each ->
              if $(this).hasClass(checkbox_trigger)
                $(this).hide()
              return
          return
        return

  # Collapse all rows via toolbar button
  $('#collapse-all-index-rows').click ->
    td = $('#disputes-index').find('td.expandable-row-column')
    $(td).each ->
      tr = $(this).closest('tr')
      row = dispute_table.row(tr)
      if row.child.isShown()
        row.child.hide()
        tr.removeClass 'shown'

  # Hide unchecked columns <- need to somehow save this 'view'
  $('.toggle-vis').each ->
    column = dispute_table.column($(this).attr('data-column'))
    checkbox = $(this).find('input')
    if $(checkbox).prop('checked')
      column.visible true
    else
      column.visible false
    $(this).on 'click', ->
      $(checkbox).prop 'checked', !checkbox.prop('checked')
      column.visible !column.visible()
      return
    $(checkbox).on 'click', ->
      $(checkbox).prop 'checked', !checkbox.prop('checked')
      return
    return
  $('.toggle-vis-nested').each ->
    checkbox_trigger = $(this).attr('data-column')
    checkbox = $(this).find('input')
    $(this).on 'click', ->
      console.log 'clicked'
      $('.dispute-entry-table td, .dispute-entry-table th').each ->
        if $(this).hasClass(checkbox_trigger)
          console.log 'match'
          $(checkbox).prop 'checked', !checkbox.prop('checked')
          $(this).toggle()
        return
      return
    $(checkbox).on 'click', ->
      $('.dispute-entry-table td, .dispute-entry-table th').each ->
        if $(this).hasClass(checkbox_trigger)
          $(checkbox).prop 'checked', !checkbox.prop('checked')
        return
      return
    return
  return

# ---
# generated by js2coffee 2.2.0

$ ->
  $(document).ready ->
    if window.location.pathname != '/escalations/webrep/tickets'
      $('#filter-cases').hide()
      $('#import-webrep').hide()
      $('#web-rep-search').hide()
    else
      $('#filter-cases').show()
      $('#import-webrep').show()
      $('#web-rep-search').show()

  $('#edit-dispute-button').click ->
    $('#dispute-priority-icon').hide()
    $('#dispute-priority-select').show()
    $('.dispute-edit-field').hide()

    $('#save-dispute-button').removeClass('hidden')
    $('#cancel-dispute-button').removeClass('hidden')
    $('#related-dispute-input').removeClass('hidden')
    $('#edit-dispute-button').addClass('hidden')


    if $('#top_bar_extended_info').css('display', 'block')
      console.log('open')
    else if $('#top_bar_extended_info').css('display', 'none')
      console.log('closed')
      $('#top-bar-toggle').addClass('top-info-open')
      $("#top_bar_extended_info").slideToggle()



  $('#cancel-dispute-button').click ->
    $('#dispute-priority-icon').show()
    $('#dispute-priority-select').hide()
    $('.dispute-edit-field').show()

    $('#save-dispute-button').addClass('hidden')
    $('#cancel-dispute-button').addClass('hidden')
    $('#related-dispute-input').addClass('hidden')
    $('#edit-dispute-button').removeClass('hidden')


  $('#index-adjust-wlbl').click ->
    console.log ('clicked!')
    tbody = $('#wlbl_adjust_entries_index').find('table.dispute_tool_current').find('tbody')
    $(tbody).empty()
    dropdown_wrapper = $(this).parent()
    if ($('.dispute-entry-checkbox:checked').length > 0)
      $('.dispute-entry-checkbox').each ->
        if $(this).prop('checked')
          entry_row = $(this).parent().parent()[0]
          entry_content = $(entry_row).find('.entry-col-content').text()
          wbrs = $(entry_row).find('.entry-col-wbrs-score').text()
          wlbl = $(entry_row).find('.entry-col-wlbl').text()

          $(tbody[0]).append('<tr><td>' + entry_content + '</td><td class="no-word-break">' + wlbl + '</td><td class="text-center">' + wbrs + '</td></tr>')
      $($('#wlbl_adjust_entries_index').find('.comment-wrapper')).show()
    else
      $(dropdown_wrapper).removeClass('open')
      alert ('No rows selected')

  $('#set-related-dispute-submit-button').click ->
    dropdown = $('#set-related-dispute-div').parent()
    orig_ticket =  $('#set-related-dispute-form').find('input.dispute-id')
    if ($('.dispute-entry-checkbox:checked').length > 0)
      if orig_ticket.val() == ''
        alert ('Please provide an original ticket number to relate the selected tickets to.')
      else
#      submit that shit
    else
      alert('No disputes selected')



#      BFRP (Research tools page)


# Inline WLBL Adjust Button
  $('.bfrp-inline-wlbl-button').click ->
#    Get entry content
    research_row = $(this).parents('.research-table-row')[0]
    entry_wrapper = $(research_row).find('.entry-data-content')[0]
    entry_content = $(entry_wrapper).text()
    wbrs = $($(research_row).find('.entry-data-wbrs-score')[0]).text()

#    Define fields that need to be filled out in the dropdown
    dropdown = $(this).next('.dropdown-menu')[0]
    wlbl_list = $(dropdown).find('.wlbl-entry-wlbl')
    wbrs_score = $(dropdown).find('.wlbl-current-entry-wbrs')
    submit_button = $(dropdown).find('.dropdown-submit-button')
    wl_weak = $(dropdown).find('.wl-weak-checkbox')
    wl_med = $(dropdown).find('.wl-med-checkbox')
    wl_heavy = $(dropdown).find('.wl-heavy-checkbox')
    bl_weak = $(dropdown).find('.bl-weak-checkbox')
    bl_med = $(dropdown).find('.bl-med-checkbox')
    bl_heavy = $(dropdown).find('.bl-heavy-checkbox')

#   Clearing data to start in case user has page open for a while and data needs to be regrabbed
    $(wlbl_list[0]).empty()
    $(wbrs_score[0]).empty()
    $(wl_weak[0]).prop('checked', false)
    $(wl_med[0]).prop('checked', false)
    $(wl_heavy[0]).prop('checked', false)
    $(bl_weak[0]).prop('checked', false)
    $(bl_med[0]).prop('checked', false)
    $(bl_heavy[0]).prop('checked', false)
    wl_weak_status = 'false'
    wl_med_status = 'false'
    wl_heavy_status = 'false'
    bl_weak_status = 'false'
    bl_med_status = 'false'
    bl_heavy_status = 'false'

#    Initializing 'current' status of lists to be filled in when data is fetched
    initial_wl_weak_status = ''
    initial_wl_med_status = ''
    initial_wl_heavy_status = ''
    initial_bl_weak_status = ''
    initial_bl_med_status = ''
    initial_bl_heavy_status = ''

    data = {
#   Send entry content to wbrs
      'entry' : entry_content
    }

    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/rule_ui_wlbl_get_info_for_form'
      method: 'GET'
      headers: headers
      data: data
      dataType: 'json'
      success: (response) ->
      #values will be in the format of BL-med, BL-weak, BL-heavy   (same with WL)

        response = JSON.parse(response)
        if response.data != ""
          $(response.data).each ->
            if String(this) == 'WL-weak'
              $(wl_weak[0]).prop('checked', true)
              wl_weak_status = 'true'
              initial_wl_weak_status = wl_weak_status
            if String(this) == 'WL-med'
              $(wl_med[0]).prop('checked', true)
              wl_med_status = 'true'
              initial_wl_med_status = wl_med_status
            if String(this) == 'WL-heavy'
              $(wl_heavy[0]).prop('checked', true)
              wl_heavy_status = 'true'
              initial_wl_heavy_status = wl_heavy_status
            if String(this) == 'BL-weak'
              $(bl_weak[0]).prop('checked', true)
              bl_weak_status = 'true'
              initial_bl_weak_stats = bl_weak_status
            if String(this) == 'BL-med'
              $(bl_med[0]).prop('checked', true)
              bl_med_status = 'true'
              initial_bl_med_status = bl_med_status
            if String(this) == 'BL-heavy'
              $(bl_heavy[0]).prop('checked', true)
              bl_heavy_status = 'true'
              initial_bl_heavy_status = bl_heavy_status

          $(wbrs_score).text(wbrs)
          $(wlbl_list[0]).text(response.data)
          $(submit_button[0]).attr('disabled', false)
        else
          $(wbrs_score).text(wbrs)
          $(wlbl_list[0]).text('Not on a list')
          $(submit_button[0]).attr('disabled', false)


      error: (response) ->
        popup_response_error(response, 'Error retrieving WL/BL Data')
    )


$ ->
  $(document).ready ->
    $('body').on 'mouseover mouseenter', '.esc-tooltipped', ->
      $(this).tooltipster
        theme: [
          'tooltipster-borderless'
          'tooltipster-borderless-customized'
          'tooltipster-borderless-comment'
          ]
        'maxWidth': 500
      $(this).tooltipster 'show'
    return
#    If user changes buttons from initial status, enable the submit button
#   TODO add this check in later that only allows user to submit if there have been changes made
