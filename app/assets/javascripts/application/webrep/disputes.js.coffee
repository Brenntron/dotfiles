window.select_or_deselect_all = (dispute_id)->


  $('.dispute-entry-checkbox_' + dispute_id).prop('checked', $('#' + dispute_id).prop('checked'))

window.populate_webrep_index_table = (data = {}) ->

  array_of_showns = []
  array_of_dispute_clicks = []
  array_of_dispute_entry_clicks = []
  array_of_dispute_entry_selectalls = []

  $('.dispute_entry_select_all').each ->
    if this.checked == true
      array_of_dispute_entry_selectalls.push this.id

  $('.dispute_check_box').each ->
    if this.checked == true
      array_of_dispute_clicks.push this.value

  $('.dispute-entry-checkbox').each ->
    if this.checked == true
      array_of_dispute_entry_clicks.push this.id

  td = $('#disputes-index').find('td.expandable-row-column')
  $(td).each ->
    tr = $(this).closest('tr')
    row = window.dispute_table.row(tr)
    if row.child.isShown()
      array_of_showns.push row.data().id

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
        $('#refresh-working-msg').hide()
        $('#refresh-error-msg').show()
        $('#refresh-error-msg').html('An error occured while retrieving data')

      else
        $('#refresh-error-msg').hide()
        $('#refresh-working-msg').show()
        $('#refresh-working-msg').html('Table data updating correctly')
        $('#dispute-index-title').text(json['title'])
        datatable = $('#disputes-index').DataTable()
        datatable.clear();
        datatable.rows.add(json.data);
        datatable.draw();
        if array_of_showns.length > 0
          for dispute_id_shown in array_of_showns
            td = $('#disputes-index').find('td.expandable-row-column')
            $(td).each ->
              tr = $(this).closest('tr')
              row = window.dispute_table.row(tr)
              #unless row.child.isShown()
              if row.data().id == dispute_id_shown
                row.child(window.format(row.data())).show()
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

        if array_of_dispute_clicks.length > 0
          for dispute_click in array_of_dispute_clicks
            $('.dispute_check_box').each ->
              if this.value == dispute_click
                this.checked = true

        if array_of_dispute_entry_clicks.length > 0
          for dispute_entry_click in array_of_dispute_entry_clicks
            $('.dispute-entry-checkbox').each ->
              if this.id == dispute_entry_click
                this.checked = true
        if array_of_dispute_entry_selectalls.length > 0
          for dispute_entry_selectall in array_of_dispute_entry_selectalls
            $('.dispute_entry_select_all').each ->
              if this.id == dispute_entry_selectall
                this.checked = true


        if undefined != json.search_name
          $('#saved-search-tbody').append(named_search_tag(json.search_name, json.search_id))

    error: (response) ->
      $('#refresh-working-msg').hide()
      $('#refresh-error-msg').show()
      $('#refresh-error-msg').html('An error occured while retrieving data')
  , this)

window.advanced_webrep_index_table = () ->
  form = $('#disputes-advanced-search-form')
  submission_types = []
  if form.find('input[name="advanced_search[submission_type]"][value="w"]').is(':checked')
    submission_types.push('w')
  if form.find('input[name="advanced_search[submission_type]"][value="e"]').is(':checked')
    submission_types.push('e')
  if form.find('input[name="advanced_search[submission_type]"][value="ew"]').is(':checked')
    submission_types.push('ew')
  data = {
    search_type: 'advanced'
    search_name: form.find('input[name="search_name"]').val()
    customer: {
      name: form.find('input[id="name-input"]').val()
      email: form.find('input[id="email-input"]').val()
      company_name: form.find('input[id="company-input"]').val()
    }
    dispute_entries: {
      ip_or_uri: form.find('input[id="dispute-input"]').val()
      suggested_disposition: form.find('input[id="disposition-input"]').val()
    }
    case_id: form.find('input[id="caseid-input"]').val()
    org_domain: form.find('input[id="domain-input"]').val()
    case_owner_username: form.find('input[id="owner-input"]').val()
    status: form.find('input[id="status-input"]').val()
    priority: form.find('input[id="priority-input"]').val()
    resolution: form.find('input[id="resolution-input"]').val()
    submission_type: submission_types
    submitter_type: form.find('input[id="submitter-input"]').val()
    submitted_older: form.find('input[id="submitted-older-input"]').val()
    submitted_newer: form.find('input[id="submitted-newer-input"]').val()
    age_older: form.find('input[id="age-older-input"]').val()
    age_newer: form.find('input[id="age-newer-input"]').val()
    modified_older: form.find('input[id="modified-older-input"]').val()
    modified_newer: form.find('input[id="modified-newer-input"]').val()
  }
  window.current_search_data = data
  window.populate_webrep_index_table(data)

window.standard_webrep_index_table = (search_name) ->
  data = {
    search_type: 'standard'
    search_name: search_name
  }
  window.current_search_data = data
  window.populate_webrep_index_table(data)

window.named_webrep_index_table = (search_name) ->
  data = {
    search_type: 'named'
    search_name: search_name
  }
  window.current_search_data = data
  window.populate_webrep_index_table(data)

window.call_contains_search = (search_form) ->
  data = {
    search_type: 'contains'
    value: search_form.querySelector('input.search-box').value
  }
  window.current_search_data = data
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

window.dispute_status_drop_down = (dispute_id) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

  $.ajax(
    url: "/escalations/api/v1/escalations/webrep/disputes/dispute_status/#{dispute_id}"
    method: 'GET'
    headers: headers
    data: {}
    dataType: 'json'
    success: (response) ->
      response = JSON.parse(response)
      status = response.status
      comment = response.comment

      $('.ticket-status-radio' + '#' + status).prop("checked", true);
      $('.ticket-status-comment').text(comment)
  )

window.dispute_resolution_drop_down = (dispute_id) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

  $.ajax(
    url: "/escalations/api/v1/escalations/webrep/disputes/dispute_resolution/#{dispute_id}"
    method: 'GET'
    headers: headers
    data: {}
    dataType: 'json'
    success: (response) ->
      response = JSON.parse(response)

      resolution = response.resolution
      resolution_comment = response.resolution_comment

      # Fill in resolution radio button and comment
      $('.dispute-resolution-' + dispute_id + '#' + resolution).prop("checked", true)
      $('#dispute-resolution-comment').text(resolution_comment)
  )

window.entry_status_drop_down = (dispute_entry_id) ->

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

  $.ajax(
    url: "/escalations/api/v1/escalations/webrep/disputes/dispute_entry_status/#{dispute_entry_id}"
    method: 'GET'
    headers: headers
    data: {}
    dataType: 'json'
    success: (response) ->
      response = JSON.parse(response)
      status = response.status

      $('.radio-dispute-' + dispute_entry_id + '#' + status).prop("checked", true);
  )

window.entry_resolution_drop_down = (dispute_entry_id) ->

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

  $.ajax(
    url: "/escalations/api/v1/escalations/webrep/disputes/dispute_entry_resolution/#{dispute_entry_id}"
    method: 'GET'
    headers: headers
    data: {}
    dataType: 'json'
    success: (response) ->
      response = JSON.parse(response)
      resolution = response.resolution
      resolution_comment = response.resolution_comment

      $('.resolution-dispute-' + dispute_entry_id + '#' + resolution).prop("checked", true)
      $('#resolution-comment-' + dispute_entry_id).text(resolution_comment)
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


window.toolbar_adjust_wlbl_button =(button_tag) ->
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


window.index_adjust_wlbl_button =(button_tag) ->
  checked_url = $('.dispute-entry-checkbox:checked')[0]
  entry_row = $(checked_url).parent().parent()[0]
  url = $(entry_row).find('.entry-col-content').text()
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
  if entry_ids.length == 0
    entry_ids = $('.dispute-entry-checkbox:checkbox:checked').map(() ->
      parseInt(this.id)
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
  comment = $('.ticket-status-comment').val()
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
  related_id = $("input[name='related_dispute_id']" ).val().split(",")
  data = {
    'relating_dispute_ids': related_id,
    'original_dispute_id': id
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
      url: '/escalations/api/v1/escalations/webrep/disputes/related_disputes'
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
        when 'status'
          if $(this).find("input[name='entry-status']:checked").attr('id') == undefined
            $(this).find(".table-entry-input")[0].innerHTML
          else
            $(this).find("input[name='entry-status']:checked").attr('id')

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



window.populate_status_selection = () ->
  nearest_selection = $(document).find("input[name='entry-status']:checked").attr('id')
  $(document).find("input[name='entry-status']:checked").closest(".inline-dropdown-menu").prev().html(nearest_selection)

window.populate_resolved_status_selection = () ->
  $('.ticket-resolution-submenu').show()

  nearest_selection = $(document).find("input[name='entry-status']:checked").attr('id')
  $(document).find("input[name='entry-status']:checked").closest(".inline-dropdown-menu").prev().html(nearest_selection)

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
  window.dispute_table = $('#disputes-index').DataTable(
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

  window.format = (dispute) ->
    table_head = '<table class="table dispute-entry-table">' + '<thead>' + '<tr>' + '<th><input class="dispute_entry_select_all" type="checkbox" onclick="select_or_deselect_all(' + dispute.id + ')" id=' + dispute.id + ' /></th>' + '<th class="entry-col-content">Dispute Entry</th>' + '<th class="entry-col-status">Dispute Entry Status</th>' + '<th class="entry-col-status">Dispute Entry Resolution</th>' + '<th class="entry-col-disp">Suggested Disposition</th>' + '<th class="entry-col-cat">Category</th>' + '<th class="entry-col-wbrs-score">WBRS Score</th>' + '<th class="entry-col-wbrs-hits">WBRS Total Rule Hits</th>' + '<th class="entry-col-wbrs-rules">WBRS Rules</th>' + '<th class="entry-col-sbrs-score">SBRS Score</th>' + '<th class="entry-col-sbrs-hits">SBRS Total Rule Hits</th>' + '<th class="entry-col-sbrs-rules">SBRS Rules</th>' + '</tr>' + '</thead>' + '<tbody>'
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
      if this.entry.was_dismissed
        important = important + ' entry-was-dismissed-flag'
      dispute_entry_id = this.entry.id
      if this.entry.wbrs_score != null
        wbrs_score = this.entry.wbrs_score
      else wbrs_score = missing_data
      if this.entry.sbrs_score != null
        sbrs_score = this.entry.sbrs_score
      else sbrs_score = missing_data
      entry_row = '<tr class="index-entry-row">' + '<td><input type="checkbox" class="dispute-entry-checkbox dispute-entry-checkbox_' + dispute.id + '" id= ' + dispute_entry_id + ' ></td>' + '<td class="entry-col-content ' + important + '">' + entry_content + '</td>' +
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

  if !location.search && $('#disputes-index').length
    standard_webrep_index_table('open')
  $('#disputes-index tbody').on 'click', 'td.expandable-row-column', ->
    tr = $(this).closest('tr')
    row = window.dispute_table.row(tr)
    if row.child.isShown()
# This row is already open - close it
      row.child.hide()
      tr.removeClass 'shown'
    else
# Open this row
      row.child(window.format(row.data())).show()
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
      row = window.dispute_table.row(tr)
      unless row.child.isShown()
        row.child(window.format(row.data())).show()
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
      row = window.dispute_table.row(tr)
      if row.child.isShown()
        row.child.hide()
        tr.removeClass 'shown'

  # Hide unchecked columns <- need to somehow save this 'view'
  $('.toggle-vis').each ->
    column = window.dispute_table.column($(this).attr('data-column'))
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
    tbody = $('#wlbl_adjust_entries_index').find('table.dispute_tool_current').find('tbody')
    show_content = $('#wlbl_adjust_entries_index').find('.wlbl-entry-content')
    if !show_content[0]
      show_content = $('#wlbl_adjust_entries_index').find('.entry-dispute-name')
    show_wlbl = $('#wlbl_adjust_entries_index').find('.wlbl-entry-wlbl')
    show_wbrs = $('#wlbl_adjust_entries_index').find('.wlbl-current-entry-wbrs')
    if !show_wbrs[0]
      show_wbrs = $('#wlbl_adjust_entries_index').find('.current-wbrs-score')
    wl_weak = $('#wlbl_adjust_entries_index').find('.wl-weak-checkbox')
    wl_med = $('#wlbl_adjust_entries_index').find('.wl-med-checkbox')
    wl_heavy = $('#wlbl_adjust_entries_index').find('.wl-heavy-checkbox')
    bl_weak = $('#wlbl_adjust_entries_index').find('.bl-weak-checkbox')
    bl_med = $('#wlbl_adjust_entries_index').find('.bl-med-checkbox')
    bl_heavy = $('#wlbl_adjust_entries_index').find('.bl-heavy-checkbox')

    $(show_content[0]).empty()
    $(show_wbrs[0]).empty()
    $(show_wlbl[0]).empty()
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

    #    $(tbody).empty()
    dropdown_wrapper = $(this).parent()
    if ($('.dispute-entry-checkbox:checked').length == 1)
      submit_button = $('#wlbl_adjust_entries_index').find('.dropdown-submit-button')
      entry_content = ''

      $('.dispute-entry-checkbox:checked').each ->

        entry_row = $(this).parent().parent()[0]
        entry_content = $(entry_row).find('.entry-col-content').text()
        wbrs = $(entry_row).find('.entry-col-wbrs-score').text()

        data = {
# Send entry content to reptool
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
                if String(this) == 'WL-med'
                  $(wl_med[0]).prop('checked', true)
                  wl_med_status = 'true'
                if String(this) == 'WL-heavy'
                  $(wl_heavy[0]).prop('checked', true)
                  wl_heavy_status = 'true'
                if String(this) == 'BL-weak'
                  $(bl_weak[0]).prop('checked', true)
                  bl_weak_status = 'true'
                if String(this) == 'BL-med'
                  $(bl_med[0]).prop('checked', true)
                  bl_med_status = 'true'
                if String(this) == 'BL-heavy'
                  $(bl_heavy[0]).prop('checked', true)
                  bl_heavy_status = 'true'

              $(show_content[0]).text(entry_content)
              $(show_wbrs[0]).text(wbrs)
              $(show_wlbl[0]).text(response.data)
              $(submit_button).attr('disabled', false)
            else
              $(show_content[0]).text(entry_content)
              $(show_wbrs[0]).text(wbrs)
              $(show_wlbl[0]).text('Not on a list')
              $(submit_button).attr('disabled', false)
#this should probably call the resync data then reload the page, for an up to date score

          error: (response) ->
            popup_response_error(response, 'Error retrieving WL/BL Data')
        )

    else
      $(dropdown_wrapper).removeClass('open')
      alert ('Please select 1 row')

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

window.populate_entry_status_dropdown = (dispute_id) ->
  std_msg_ajax(
    url: "/escalations/api/v1/escalations/webrep/disputes/dispute_entry_status/#{dispute_id}"
    method: 'GET'
    data: {}
    dataType: 'json'
    success: (response) ->
      response = JSON.parse(response)
      status = response.status

      $('.entry-status-radio' + '.' + status + '_' + dispute_id).prop("checked", true)
  )

window.populate_resolution_dropdown = (dispute_id) ->
  std_msg_ajax(
    url: "/escalations/api/v1/escalations/webrep/disputes/dispute_entry_resolution/#{dispute_id}"
    method: 'GET'
    data: {}
    dataType: 'json'
    success: (response) ->
      response = JSON.parse(response)
      status = response.status

      $('.entry-status-radio' + '.' + status + '_' + dispute_id).prop("checked", true)
  )


$ ->
  $(document).ready ->

    setInterval ->
      if window.current_search_data
        window.populate_webrep_index_table(window.current_search_data)
    , 60000

    $('body').on 'mouseover mouseenter', '.esc-tooltipped', ->
      $(this).tooltipster
        debug: false,
        theme: [
          'tooltipster-borderless'
          'tooltipster-borderless-customized'
          'tooltipster-borderless-comment'
          ]
        'maxWidth': 500
      $(this).tooltipster 'show'
    return

window.makeBar = (id, data) ->
  ctx = document.getElementById(id).getContext('2d')
  window.myBar = new Chart(ctx,
    type: 'bar'
    data:
      labels: [
        'September 2',
        'September 3',
        'September 4',
        'September 5',
        'September 6',
        'September 7',
        'September 8'
      ]
      datasets: data
    options:
      responsive: true
      legend: false
      title:
        display: true
        position: 'bottom'
        text: 'Dates'
      scales:
        yAxes: [
          {
            gridLines:
              display: false
            ticks: {
              min: 0
              stepSize: 10
            }
          }
        ]
        xAxes: [
          {
            gridLines: display: false
            ticks: {
              autoSkip: false
            }
          }
        ]
  )
  return

$ ->
  window.updateGraph = (label, barName, el) ->
    originalData = []
    if barName == 'myBar'
      originalData = window.barDataSets
    else if barName == 'barChartGrouped'
      originalData = window.barChartGroupedData

    if $(el)[0].checked
      currentData = window[barName].data.datasets
      window[barName].data.datasets = currentData.concat originalData.filter (x) -> label.indexOf(x.label) >= 0
      window[barName].update()
    else
      currentData = window[barName].data.datasets
      window[barName].data.datasets = currentData.filter (x) -> label.indexOf(x.label) < 0
      window[barName].update()

  $(document).ready ->

    if window.location.pathname.endsWith('dashboard')
      window.barDataSets = [
        {
          label: 'Total Ticket Entries'
          backgroundColor: '#6dbcdb'
          data: [
            20
            24
            30
            28
            0
            0
            0
          ]
        }
        {
          label: 'W'
          backgroundColor: '#E47433'
          data: [
            15
            20
            18
            20
            0
            0
            0
          ]
        }
        {
          label: 'EW'
          backgroundColor: '#8CC63F'
          data: [
            8
            7
            15
            12
            0
            0
            0
          ]
        }
        {
          label: 'E'
          backgroundColor: '#BA55D3'
          data: [
            0
            0
            0
            9
            0
            0
            0
          ]
        }
      ]
      barDataSet = barDataSets
      makeBar('canvas', barDataSet)

      $('.graph-config select').on 'change', (el) ->
        if el.target.value == 'yearly'
          barDataSet = window.myBar.data.datasets
          window.myBar.data.datasets = barDataSet.concat barDataSets.filter (x) -> x.label == 'Total Ticket Entries'
          window.myBar.update()
        else if el.target.value == 'montly'
          barDataSet = window.myBar.data.datasets.filter (x) -> x.label != 'E' and x.label != 'W' and x.label != 'EW'
          window.myBar.data.datasets = barDataSet
          window.myBar.update()
        else if el.target.value == 'weekly'
          barDataSet = window.myBar.data.datasets.filter (x) -> x.label != 'E' and x.label != 'W' and x.label != 'EW'
          window.myBar.data.datasets = barDataSet
          window.myBar.update()
        else
          window.myBar.data.datasets = barDataSets
          window.myBar.update()

      new Chart(document.getElementById('pie-chart'),
        type: 'pie'
        data:
          labels: [
            'Fixed'
            'Unchanged'
            'Fixed FP'
          ]
          datasets: [ {
            label: 'close-email-entries'
            backgroundColor: [
              '#3e5a72'
              '#6dbcdb'
              '#666'
            ]
            data: [
              5078
              4367
              2152
            ]
          } ]
        options:
          legend: false
          pieceLabel:
            render: (args) ->
              return args.percentage + '%'
            position: 'outside'
            segment: false
            precision: 2
            showZero: true
            fontStyle: 'bolder'
            overlap: false
            showActualPercentages: true
      )



      new Chart(document.getElementById('pie-chart2'),
        type: 'pie'
        data:
          labels: [
            'Fixed'
            'Unchanged'
            'Fixed FP'
          ]
          datasets: [ {
            label: 'close-email-entries'
            backgroundColor: [
              '#3e5a72'
              '#6dbcdb'
              '#666'
            ]
            data: [
              2478
              3267
              4202
            ]
          } ]
        options:
          legend: false
          pieceLabel:
            render: (args) ->
              return args.percentage + '%'
            position: 'outside'
            label: 'Unchanched'
            segment: false
            precision: 2
            showZero: true
            fontStyle: 'bolder'
            overlap: false
            showActualPercentages: true

      )



      new Chart(document.getElementById('line-chart'),
        type: 'line'
        data:
          labels: [
            0
            1
            3
            4
            5
            6
            7
            8
            9
            10
            11
          ]
          datasets: [
            {
              data: [
                1
                1.3
                1.2
                1.5
                1.7
                1.4
                1.8
                0.9
                1
                1.1
                1.2
                1.5
                1.6
              ]
              label: 'close'
              backgroundColor: '#6dbcdb'
              fill: true
              lineTension: 0
            }
            {
              data: [
                1.4
                1.4
                1.4
                1.4
                1.4
                1.4
                1.4
                1.4
                1.4
                1.4
                1.4
              ]
              label: 'ticket'
              backgroundColor: 'rgba(135, 206, 250, .1)'
              fill: true
              lineTension: 0
            }
          ]
        options:
          legend: false
          elements:
            point:
              radius: 0
          scales:
            yAxes: [
              {
                gridLines:
                  display: false
                ticks: {
                  min: 0
                  stepSize: .5
                  callback: (value, index, values) ->
                    if value > 1
                      return value + ' hr'
                    else
                      return value + ' hr'
                }
              }
            ]
            xAxes: [
              {
                gridLines:
                  display: false
                scaleLabel: {
                  display: true,
                  labelString: 'Tikets'
                }
                ticks: {
                  display: false
                }
              }
            ])


      # Bar chart
      new Chart(document.getElementById('bar-chart'),
        type: 'bar'
        data:
          labels: [
            'September 2',
            'September 3',
            'September 4',
            'September 5',
            'September 6',
            'September 7',
            'September 8'
          ]
          datasets: [
            {
            label: 'Customer'
            backgroundColor: '#6dbcdb'
            data: [
              20
              24
              30
              28
            ]
            }
            {
              label: 'Guest'
              backgroundColor: '#3e5a72'
              data: [
                15
                8
                18
                16
              ]
            }]
        options:
          legend:
            display: false

          scales:
            yAxes: [
              {
                gridLines: display: false
                ticks: {
                  min: 0
                  stepSize: 10
                }
              }
            ]
            xAxes: [
              {
                gridLines: display: false
                ticks: {
                  autoSkip: false
                }
              }
            ]
        )

#    graph bottom
    if window.location.pathname.endsWith('teamtickets')
      new Chart(document.getElementById('bar-chart-horizontal'),
        type: 'horizontalBar'
        data:
          labels: [
            'mtaylor'
            'chrclair'
            'nherbert'
            'nverbeck'
            'abreeeman'
          ]
          datasets: [ {
            backgroundColor: [
              '#6dbcdb'
              '#6dbcdb'
              '#6dbcdb'
              '#6dbcdb'
              '#6dbcdb'
            ]
            data: [
              8
              15
              11
              10
              13.5
            ]
          } ]
        options:
          legend: display: false
          scales:
            yAxes: [
              {
                gridLines: display: false
                ticks: {
                  min: 0
                  stepSize: 10
                }
              }
            ]
            xAxes: [
              {
                gridLines: display: false
                ticks: {
                  min: 0
                  stepSize: 5
                  max: 20
                }
                scaleLabel: {
                  display: true,
                  labelString: 'Tickets'
                }
              }
            ]
          )

      new Chart(document.getElementById('bar-chart2-horizontal'),
        type: 'horizontalBar'
        data:
          labels: [
            'mtaylor'
            'chrclair'
            'nherbert'
            'nverbeck'
            'abreeeman'
          ]
          datasets: [ {
            backgroundColor: [
              '#6dbcdb'
              '#6dbcdb'
              '#6dbcdb'
              '#6dbcdb'
              '#6dbcdb'
            ]
            data: [
              .8
              .7
              1.7
              1.6
              2
            ]
          } ]
        options:
          legend: display: false
          scales:
            yAxes: [
              {
                gridLines: display: false
                ticks: {
                  min: 0
                  stepSize: 1
                }
              }
            ]
            xAxes: [
              {
                gridLines: display: false
                ticks: {
                  min: 0
                  stepSize: 1
                  max: 4
                }
                scaleLabel: {
                  display: true,
                  labelString: 'hours'
                }
              }
            ]
      )

      new Chart(document.getElementById('bar-chart-grouped'),
        type: 'bar'
        data:
          labels: [
            'mtaylor'
            'chrclair'
            'nherbert'
            'nverbeck'
            'abreeman'
          ]
          datasets: [
            {
              label: 'Fixed FP'
              backgroundColor: '#6dbcdb'
              data: [
                9.5
                7.5
                5
                6.5
                9.5
              ]
            }
            {
              label: 'Fixed FN'
              backgroundColor: '#2c3e50'
              data: [
                10.5
                14
                11.5
                10
                5
              ]
            }
            {
              label: 'Unchanged'
              backgroundColor: '#999'
              data: [
                3.5
                4.8
                11.5
                13.5
                9.5
              ]
            }
            {
              label: 'Other'
              backgroundColor: '#E47433'
              data: [
                0
                1.5
                0
                3.5
                1.5
              ]
            }
          ]
        options:
          title:
            display: false
          legend: display: false
          scales:
            yAxes: [
              {
                gridLines: display: false
                ticks: {
                  min: 0
                  stepSize: 5
                  max: 15
                }
              }
            ]
            xAxes: [
              {
                gridLines: display: false
              }
            ]
      )

      new Chart(document.getElementById('bar-chart3-horizontal'),
        type: 'horizontalBar'
        data:
          labels: [
            'a500'
            'alx_ cln'
            'mute_phish'
            'sbl'
            'srch'
            'suwl'
            'trd_mal'
          ]
          datasets: [ {
            backgroundColor: [
              '#6dbcdb'
              '#6dbcdb'
              '#6dbcdb'
              '#6dbcdb'
              '#6dbcdb'
              '#6dbcdb'
              '#6dbcdb'
            ]
            data: [
              5
              18.5
              9.5
              14.5
              4.5
              7.5
              3
            ]
          } ]
        options:
          legend: display: false
          scales:
            yAxes: [
              {
                gridLines: display: false
              }
            ]
            xAxes: [
              {
                gridLines: display: false
                ticks: {
                  min: 0
                  stepSize: 5
                  max: 20
                }
                scaleLabel: {
                  display: true,
                  labelString: 'Total Ticket Entries with FP Resolutions'
                }
              }
            ]
      )
      window.barChartGroupedData = [
        {
          label: 'Total Ticket Entries'
          backgroundColor: '#6dbcdb'
          data: [
            15
            18
            22
            18
          ]
        }
        {
          label: 'E'
          backgroundColor: '#8cc63f'
          data: [
            0
            0
            0
            0
          ]
        }
        {
          label: 'W'
          backgroundColor: '#E47433'
          data: [
            0
            0
            0
            0
          ]
        }
        {
          label: 'EW'
          backgroundColor: '#BA55D3'
          data: [
            0
            0
            0
            0
          ]
        }
      ]
      window.barChartGrouped = new Chart(document.getElementById('bar-chart2-grouped'),
        type: 'bar'
        data:
          labels: [
            'September 2'
            'September 3'
            'September 4'
            'September 5'
            'September 6'
            'September 7'
            'September 8'
          ]
          datasets: window.barChartGroupedData
        options:
          legend: display: false
          scales:
            yAxes: [
              {
                gridLines: display: false
              }
            ]
            xAxes: [
              {
                gridLines: display: false
                ticks: {
                  autoSkip: false
                }
              }
            ]
        )

      new Chart(document.getElementById('bar-chart3-grouped'),
        type: 'bar'
        data:
          labels: [
            'September 2'
            'September 3'
            'September 4'
            'September 5'
            'September 6'
            'September 7'
            'September 8'
          ]
          datasets: [
            {
              backgroundColor: '#6dbcdb'
              data: [
                15
                18
                22
                18
              ]
            }
            {
              backgroundColor: '#2c3e50'
              data: [
                8.5
                5.5
                13.5
                8.5
              ]
            }
          ]
        options:
          legend: display: false
          scales:
            yAxes: [
              {
                gridLines: display: false
                ticks: {
                  min: 0
                  stepSize: 10
                  max: 30
                }
              }
            ]
            xAxes: [
              {
                gridLines: display: false
                ticks: {
                  autoSkip: false
                }
              }
            ]
      )

      new Chart(document.getElementById('team-pie-chart'),
        type: 'pie'
        data:
          labels: [
            'Fixed'
            'Unchanged'
            'Fixed FP'
          ]
          datasets: [ {
            label: 'close-email-entries'
            backgroundColor: [
              '#3e5a72'
              '#6dbcdb'
              '#666'
            ]
            data: [
              5178
              4267
              2202
            ]
          } ]
        options:
          legend: false
          pieceLabel:
            render: (args) ->
              return args.percentage + '%'
            position: 'outside'
            label: 'Unchanched'
            segment: false
            precision: 2
            showZero: true
            fontStyle: 'bolder'
            overlap: false
            showActualPercentages: true

      )

      new Chart(document.getElementById('team-pie2-chart'),
        type: 'pie'
        data:
          labels: [
            'Fixed'
            'Unchanged'
            'Fixed FP'
          ]
          datasets: [ {
            label: 'close-email-entries'
            backgroundColor: [
              '#3e5a72'
              '#6dbcdb'
              '#666'
            ]
            data: [
              3778
              4767
              5900
            ]
          } ]
        options:
          legend: false
          pieceLabel:
            render: (args) ->
              return args.percentage + '%'
            position: 'outside'
            label: 'Unchanched'
            segment: false
            precision: 2
            showZero: true
            fontStyle: 'bolder'
            overlap: false
            showActualPercentages: true

      )


