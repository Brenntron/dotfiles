$(document).ready ->
  Chart.defaults.global.plugins.datalabels.display = false
  $('span#mark-as-related').on 'show.bs.dropdown', ->
    if $('.dispute_check_box:checked').length == 0
      std_msg_error('No rows selected', ['Please select at least one row.'])
      return false

window.select_or_deselect_all = (dispute_id)->

  $('.dispute-entry-checkbox_' + dispute_id).prop('checked', $('#' + dispute_id).prop('checked'))
  $('.dispute-entry-checkbox_' + dispute_id).each ->
    toggleRow(this)

window.populate_webrep_index_table = (data = {}, reload = false) ->
  data['reload'] = reload

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
  $('#loader-modal').modal({
    backdrop: 'static',
    keyboard: false
  })
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
        $('#loader-modal').modal 'hide'
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
        datatable.draw(false);
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
                      $('#loader-modal').modal 'hide'
                      return
                  else if $(checkbox).prop('checked') == false
                    $('.dispute-entry-table td, .dispute-entry-table th').each ->
                      if $(this).hasClass(checkbox_trigger)
                        $(this).hide()
                      $('#loader-modal').modal 'hide'
                      return
                  $('#loader-modal').modal 'hide'
                  return
                $('#loader-modal').modal 'hide'
                return

        if array_of_dispute_clicks.length > 0
          for dispute_click in array_of_dispute_clicks
            $('.dispute_check_box').each ->
              if this.value == dispute_click
                this.checked = true
                datatable.row(this.closest('tr')).select()

        if array_of_dispute_entry_clicks.length > 0
          for dispute_entry_click in array_of_dispute_entry_clicks
            $('.dispute-entry-checkbox').each ->
              if this.id == dispute_entry_click
                this.checked = true
                toggleRow(this)
        if array_of_dispute_entry_selectalls.length > 0
          for dispute_entry_selectall in array_of_dispute_entry_selectalls
            $('.dispute_entry_select_all').each ->
              if this.id == dispute_entry_selectall
                this.checked = true

        if undefined != json.search_name
          searchId = 'saved_search_' + json.search_id
          if $('#saved-search-tbody tr#' + searchId).length == 0
            $('#saved-search-tbody').append(named_search_tag(json.search_name, json.search_id))
        $('#loader-modal').modal 'hide'

    error: (response) ->
      $('#loader-modal').modal 'hide'
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
  dispute_save_search_format = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/
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
  if dispute_save_search_format.test(data.search_name) == true
    std_msg_error('save search name error', ['Please enter a name without any special character', 'Example: !@#$%^&*()'])
  else
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

      $('.ticket-status-radio' + '#' + status).prop("checked", true)
      if comment?
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
      $('.ticket-resolution-comment').text(resolution_comment)
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


window.save_dispute = () ->
  data = {
    'priority': $('#dispute-priority-select').val()
    'customer_name': $('#dispute-customer-name-input').val()
    'customer_email': $('#dispute-customer-email-input').val()
    'status': $('#status').val()
    'submission_type': $('#dispute-submission-type-select').val().toLowerCase()
  }

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/' + $('#dispute_id').text()
    method: 'PUT'
    data: data
    error_prefix: 'Unable to update dispute.'
    success_reload: true
  )


window.toolbar_index_edit_status = () ->
  statusName = $('input[name=entry-status]:checked').val()

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
        new: $('input[name=entry-resolution]:checked').val()
      })

      data[this.id].push({
        id: this.id
        field: "resolution_comment"
        new: $('#entry-status-comment').val()
      })
  )

  if statusName == "RESOLVED_CLOSED" && !$('input[name=entry-resolution]:checked').val()
    std_msg_error('No resolution selected', ['Please select an entry resolution.'])
  else
    std_msg_ajax(
      method: 'PATCH'
      url: "/escalations/api/v1/escalations/webrep/disputes/entries/field_data"
      data: { field_data: data }
      success_reload: true
      error_prefix: 'Error updating data.'
    )


window.show_page_edit_status = () ->
  statusName = $('input[name=dispute-status]:checked').val()
  comment = $('.ticket-status-comment').val()
  dispute_id = $('#dispute_id').text()

  if statusName == "RESOLVED_CLOSED"
    if $('#show-edit-ticket-status-dropdown').find('input[name=dispute-resolution]').is(':checked')
      resolution = $('input[name=dispute-resolution]:checked').val()
    else
      std_msg_error('No resolution selected', ['Please select a ticket resolution.'])
      return

  data = {
    dispute_ids: [ dispute_id ]
    status: statusName
    comment: comment
  }

  if resolution
    data.resolution = resolution
    data.comment = $('.ticket-resolution-comment').val()

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
      std_msg_error('no rows selected', ['Please select at least one row to change assignee.'])
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
      std_msg_error('No Tickets Selected', ['Select at least one ticket to assign to yourself.'])
  )

window.related_disputes = () ->
  entry_ids = $('.dispute_check_box:checkbox:checked').map(() ->
    Number(this.value)
  ).toArray()

  original_dispute_id = $('.dispute-id').val()

  # Make sure that the original dispute ID is provided by the user.
  # If it is not then display an error
  if original_dispute_id.trim() == ''
    std_msg_error('Ticket not marked as related', ['Please enter the original ticket number to relate ticket to.'])
    return

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
    error: (error) ->
      std_msg_error('Ticket not marked as related', ['Error setting related dispute', error.responseJSON.error])
      $('.dispute-id').val('')
      $('span#mark-as-related .dropdown-menu').hide()

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
  entry_content = $('#add_dispute_entry').val()
  if $.trim(entry_content) == '' || entry_content == null
#    Do not allow accidental submission of empty or blank spaced entry
    std_msg_error('Entry content cannot be blank', ['Please provide content for the new entry.'])
    return false
  else
    $('#loader-modal').modal({
      backdrop: 'static',
      keyboard: true
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

  if dispute_ids.length == 0
    std_msg_error('No Tickets Selected', ['Please select at least one ticket to assign.'])
    return

  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/webrep/disputes/take_disputes"
    data: { dispute_ids: dispute_ids }
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      for dispute_id in response.dispute_ids
        $('#owner_' + dispute_id).text(response.username)
        $('#status_' + dispute_id).text("Assigned")
      std_msg_success('Tickets successfully assigned', [response.dispute_ids.length + ' have been assigned to ' + response.username])
    error: (error) ->
      std_msg_error('Assign Issue(s) Error', [
        'Failed to assign ' + dispute_ids.length + ' issue(s).',
        'Due to: ' + error.responseJSON.error
      ])
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
  if $('input[name=entry-status]:checked').attr('id') == "RESOLVED_CLOSED" && !$('input[name=entry-resolution]:checked').val()
    std_msg_error('No resolution selected', ['Please select a ticket resolution.'])
  else
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

window.change_ticket_status = (event) ->
#  event.preventDefault()
  status = $('#index-edit-ticket-status-dropdown').find('.ticket-status-radio:checked').val()
  resolution = ""
  comment = ""
  checkboxes = $('#disputes-index').find('.dispute_check_box')
  checked_disputes = []
  
  $(checkboxes).each ->
    if $(this).is(':checked')
      dispute_id = $(this).val()
      checked_disputes.push(dispute_id)

  if status == 'RESOLVED_CLOSED'
    if $('#index-edit-ticket-status-dropdown').find('.ticket-resolution-radio').is(':checked')
      resolution = $('#index-edit-ticket-status-dropdown').find('.ticket-resolution-radio:checked').val()
      comment = $('.resolution-comment-wrapper').find('.ticket-status-comment').val()
    else
      std_msg_error('No resolution selected', ['Please select a ticket resolution.'])
      return
  else
    comment = $('.non-resolution-submit-wrapper').find('.ticket-status-comment').val()

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  data = {
    status: status,
    resolution: resolution,
    comment: comment
  }

  for dispute in checked_disputes
#    event.preventDefault()
    data.dispute_ids = dispute
    $.ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/set_disputes_status'
      method: 'POST'
      headers: headers
      data: data
      mimeType: 'application/json'
      success: (response) ->
        window.location.reload()
      error: (response) ->
        if response.status > 400
          popup_response_error(response, 'Error Updating Status')
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

window.webrep_reset_search = () ->
  inputs = document.getElementsByClassName('form-control')

  for i in inputs
    i.value = ""

$ ->

#  Opens ticket status resolution back up after modal close
  $('#msg-modal').on 'hide.bs.modal', (e) ->
    if $('#index-edit-ticket-status-dropdown').parent().hasClass('open')
      $('#msg-modal').on 'hidden.bs.modal', (b) ->
        $('#index-edit-ticket-status-dropdown').parent().addClass('open')
    if $('#show-edit-ticket-status-dropdown').parent().hasClass('open')
      $('#msg-modal').on 'hidden.bs.modal', (c) ->
        $('#show-edit-ticket-status-dropdown').parent().addClass('open')
    if $('#index-edit-entry-status-dropdown').parent().hasClass('open')
      $('#msg-modal').on 'hidden.bs.modal', (d) ->
        $('#index-edit-entry-status-dropdown').parent().addClass('open')

  window.toggleRow = (box) ->
    if $(box)[0].checked
      $(box).closest('tr').addClass('selected')
    else
      $(box).closest('tr').removeClass('selected')

  $('.ticket-status-radio').click ->
    all_stat_radios = $('#index-edit-ticket-status-dropdown').find('.status-radio-wrapper')
    if $(this).is(':checked')
      wrapper = $(this).parent()
      $(all_stat_radios).removeClass('selected')
      $(wrapper).addClass('selected')

    if $(this).attr('id') == 'RESOLVED_CLOSED'
#      debugger
      $('#show-ticket-resolution-submenu').show()
      stat_comment = $('#ticket-non-res-submit').find('.ticket-status-comment')
      $('#ticket-non-res-submit').hide()
      $(stat_comment).val('')
    else
      $('#ticket-non-res-submit').show()
      res_comment = $('.resolution-comment-wrapper').find('.ticket-status-comment')
      $('.ticket-resolution-radio').prop('checked', false)
      $('#show-ticket-resolution-submenu').hide()
      $(res_comment[0]).val('')

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
      std_msg_error('No rows selected', ['Please select at least one row.'])

  # Edit Entry: Edit Entry Status
  $('#index-entry-status-button').click ->
    dropdown = $('#index-edit-entry-status-dropdown').parent()
    if ($('.dispute-entry-checkbox:checked').length > 0)

      $('.entry-status-radio-label').click ->
        radio_button = $(this).prev('.entry-status-radio')
        $(radio_button[0]).trigger('click')
        if $(radio_button).val() == 'RESOLVED_CLOSED'
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
        if $(this).val() == 'RESOLVED_CLOSED'
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
      std_msg_error('No rows selected', ['Please select at least one row.'])
      return false

  # Create index table
  window.dispute_table = $('#disputes-index').DataTable(
    order: [ [
      9
      'desc'
    ] ]
    dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
    language: {
      search: "_INPUT_"
      searchPlaceholder: "Search within table"
    }
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
        targets: [ 10 ]
        className: 'age-col'
        orderData: 18
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

          '<input type="checkbox" onclick="toggleRow(this)" name="cbox" class="dispute_check_box" id="cbox' + data + '" value="' + data + '" />'

      }
      {
        data: 'priority'
        render: (data) ->
          '<span class="bug-priority p-' + data + '">' + data + '</span>'

      }
      { data: 'case_link' }
      { data: 'status' }
      {
        data: 'dispute_resolution'
      }
      {
        data: 'submission_type'
        render: (data) ->
          title = ''
          if data == 'w'
            title = 'Web'
          else if data == 'e'
            title = 'Email'
          else if data == 'ew'
            title = 'Email Web'
          '<span class="dispute-submission-type esc-tooltipped dispute-' + data + '" title="' + title + '">' + data + '</span>'
      }
      { data: 'd_entry_preview' }
      { data: 'assigned_to' }
      { data: 'case_opened_at' }
      {
        data: 'case_age'
        'render':(data,type,full,meta) ->
          if data != "<1 hr"
            dispute_duration = moment(full.case_opened_at).fromNow()
            if dispute_duration.includes('minute')
              dispute_latency = data
            if dispute_duration.includes('hour')
              hours = parseInt(dispute_duration.replace(/[^0-9]/g, ''))
              if hours <= 3
                dispute_latency = data
              else
                dispute_latency = '<span class="ticket-age-over3hr">' + data + '</span>'
              if hours > 12
                dispute_latency = '<span class="ticket-age-over12hr">' + data + '</span>'
            else
              dispute_latency = '<span class="ticket-age-over12hr">' + data + '</span>'
            if dispute_duration.includes('day')
              day = parseInt(data.replace(/[^0-9]/g, ''))
              if day >= 1
                dispute_latency = '<span class="ticket-age-over12hr">' + data + '</span>'
            if dispute_duration.includes('months')
              month = parseInt(data.replace(/[^0-9]/g, ''))
              dispute_latency = '<span class="ticket-age-over12hr">' + data + '</span>'
            if dispute_duration.includes('year')
              year = parseInt(data.replace(/[^0-9]/g, ''))
              dispute_latency = '<span class="ticket-age-over12hr">' + data + '</span>'
            dispute_latency
          else
            data
      }
      { data: 'source' }
      { data: 'submitter_type'}
      { data: 'submitter_org' }
      { data: 'submitter_domain' }
      { data: 'submitter_name' }
      { data: 'submitter_email' }
      { data: 'status_comment' }
      {
        data: 'age_int'
        visible: false
      }


    ])
  $('#disputes-index_filter input').addClass('table-search-input');
  window.format = (dispute) ->
    table_head = '<table class="table dispute-entry-table">' + '<thead>' + '<tr>' + '<th><input class="dispute_entry_select_all" type="checkbox" onclick="select_or_deselect_all(' + dispute.id + ')" id=' + dispute.id + ' /></th>' + '<th class="entry-col-content">Dispute Entry</th>' + '<th class="entry-col-status">Dispute Entry Status</th>' + '<th class="entry-col-res">Dispute Entry Resolution</th>' + '<th class="entry-col-disp">Suggested Disposition</th>' + '<th class="entry-col-cat">Category</th>' + '<th class="entry-col-wbrs-score">WBRS Score</th>' + '<th class="entry-col-wbrs-hits">WBRS Total Rule Hits</th>' + '<th class="entry-col-wbrs-rules">WBRS Rules</th>' + '<th class="entry-col-sbrs-score">SBRS Score</th>' + '<th class="entry-col-sbrs-hits">SBRS Total Rule Hits</th>' + '<th class="entry-col-sbrs-rules">SBRS Rules</th>' + '</tr>' + '</thead>' + '<tbody>'
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
      if this.entry.resolution_comment != null
        resolution_comment = this.entry.resolution_comment
        resolution_col = '<td class="entry-col-res esc-tooltipped" title="' + resolution_comment + '">' + resolution + '</td>'
      else
        resolution_col = '<td class="entry-col-res">' + resolution + '</td>'
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
      entry_row = '<tr class="index-entry-row" data-case-id="0000' + dispute.id + '">' + '<td><input type="checkbox" onclick="toggleRow(this)" class="dispute-entry-checkbox dispute-entry-checkbox_' + dispute.id + '" id= ' + dispute_entry_id + ' ></td>' + '<td class="entry-col-content ' + important + '">' + entry_content + '</td>' +
        '<td class="entry-col-status">' + status + '</td>' +
        resolution_col +
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
  $('#disputes-index tbody').on 'click', 'td.expandable-row-column, .dispute-count', ->
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
      $(checkbox).prop 'checked', !checkbox.prop('checked')
      $('.dispute-entry-table td, .dispute-entry-table th').each ->
        if $(this).hasClass(checkbox_trigger)
          $(this).toggle()
        return
      return
    $(checkbox).on 'click', ->
      $(checkbox).prop 'checked', !checkbox.prop('checked')
      return
    return
  return

# ---
# generated by js2coffee 2.2.0

$ ->

  $('#new-dispute').click ->
    std_msg_ajax(
      method: 'GET'
      url: '/escalations/api/v1/escalations/webrep/disputes/populate_new_dispute_fields'
      success: (response) ->
        for user in response.json.assignees
          $('#assignee-list').append '<option value=\'' + user.cvs_username + '\'></option>'
    )

  $('#advanced-search-button').click ->
    std_msg_ajax(
      method: 'GET'
      url: '/escalations/api/v1/escalations/webrep/disputes/autopopulate_advanced_search'
      success: (response) ->

        $('#user-list').empty()
        $('#status-list').empty()
        $('#submittertype-list').empty()
        $('#contactname-list').empty()
        $('#contactemail-list').empty()
        $('#company-list').empty()
        $('#resolution-list').empty()


        for user in response.json.case_owners
          $('#user-list').append '<option value=\'' + user.cvs_username + '\'></option>'

        for status in response.json.statuses
          $('#status-list').append '<option value=\'' + status + '\'></option>'

        for type in response.json.submitter_types
          $('#submittertype-list').append '<option value=\'' + type + '\'></option>'

        for contact in response.json.contacts
          $('#contactname-list').append '<option value=\'' + contact.name + '\'></option>'

        for contact in response.json.contacts
          $('#contactemail-list').append '<option value=\'' + contact.email + '\'></option>'

        for company in response.json.companies
          $('#company-list').append '<option value=\'' + company.name + '\'></option>'

        for resolution in response.json.resolutions
          $('#resolution-list').append '<option value=\'' + resolution + '\'></option>'
    )


  $(document).ready ->

    if window.location.pathname == '/escalations/webrep/disputes'
      $('#new-complaint').show()
    else
      $('#new-complaint').hide()

    if window.location.pathname == '/escalations/webrep/disputes'
      std_msg_ajax(
        method: 'POST'
        url: "/escalations/api/v1/escalations/user_preferences/"
        data: {name: 'WebRepColumns'}
        success: (response) ->
          response = JSON.parse(response)

          $.each response, (column, state) ->
            if state == true
              $("##{column}-checkbox").prop('checked', true)
              window.dispute_table.column("##{column}").visible true
            else
              $("##{column}-checkbox").prop('checked', false)
              window.dispute_table.column("##{column}").visible false

      )

    $('.toggle-vis').on "click", ->
      data = {}
      data['priority'] = $("#priority-checkbox").is(':checked')
      data['case-id'] = $("#case-id-checkbox").is(':checked')
      data['status'] = $("#status-checkbox").is(':checked')
      data['resolution'] = $("#resolution-checkbox").is(':checked')
      data['submission-type'] = $("#submission-type-checkbox").is(':checked')
      data['dispute'] = $("#dispute-checkbox").is(':checked')
      data['owner'] = $("#owner-checkbox").is(':checked')
      data['time-submitted'] = $("#time-submitted-checkbox").is(':checked')
      data['age'] = $("#age-checkbox").is(':checked')
      data['case-origin'] = $("#case-origin-checkbox").is(':checked')
      data['submitter-type'] = $("#submitter-type-checkbox").is(':checked')
      data['submitter-org'] = $("#submitter-org-checkbox").is(':checked')
      data['submitter-domain'] = $("#submitter-domain-checkbox").is(':checked')
      data['contact-name'] = $("#contact-name-checkbox").is(':checked')
      data['contact-email'] = $("#contact-email-checkbox").is(':checked')
      data['status-comment'] = $("#status-comment-checkbox").is(':checked')

      std_msg_ajax(
        url: "/escalations/api/v1/escalations/user_preferences/update"
        method: 'POST'
        data: {data, name: 'WebRepColumns'}
        dataType: 'json'
        success: (response) ->
      )

    $('.toggle-vis-nested').on "click", ->
      data = {}
      data['dispute-entry'] = $("#dispute-entry-checkbox").is(':checked')
      data['entry-status'] = $("#entry-status-checkbox").is(':checked')
      data['entry-resolution'] = $("#entry-resolution-checkbox").is(':checked')
      data['suggested-disposition'] = $("#suggested-disposition-checkbox").is(':checked')
      data['category'] = $("#category-checkbox").is(':checked')
      data['wbrs-score'] = $("#wbrs-score-checkbox").is(':checked')
      data['wbrs-total-rule-hits'] = $("#wbrs-total-rule-hits-checkbox").is(':checked')
      data['wbrs-rules'] = $("#wbrs-rules-checkbox").is(':checked')
      data['sbrs-score'] = $("#sbrs-score-checkbox").is(':checked')
      data['sbrs-total-rule-hits'] = $("#sbrs-total-rule-hits-checkbox").is(':checked')
      data['sbrs-rules'] = $("#sbrs-rules-checkbox").is(':checked')

      std_msg_ajax(
        url: "/escalations/api/v1/escalations/user_preferences/update"
        method: 'POST'
        data: {data, name: 'WebRepColumns'}
        dataType: 'json'
        success: (response) ->
      )


    if window.location.pathname != '/escalations/webrep/disputes'
      $('#filter-cases').hide()
      $('#import-webrep').hide()
      $('#web-rep-search').hide()
    else
      $('#filter-cases').show()
      $('#import-webrep').show()
      $('#web-rep-search').show()

  $('#edit-dispute-button').click ->
    $('.dispute-submission-type').hide()
    $('#dispute-submission-type-select').show()

    $('#dispute-priority-icon').hide()
    $('#dispute-priority-select').show()

    $('#dispute-customer-name').hide()
    $('#dispute-customer-email').hide()

    $('.dispute-edit-input').css('display','block')

    $('#save-dispute-button').removeClass('hidden')
    $('#cancel-dispute-button').removeClass('hidden')
    $('#related-dispute-input').removeClass('hidden')
    $('#edit-dispute-button').addClass('hidden')


    if $('#top_bar_extended_info').css('display', 'none')
      $('#top-bar-toggle').addClass('top-info-open')
      $("#top_bar_extended_info").slideToggle()



  $('#cancel-dispute-button').click ->
    $('#dispute-priority-icon').show()
    $('#dispute-priority-select').hide()
    $('.dispute-edit-field').show()
    $('#dispute-submission-type-select').hide()
    $('.dispute-submission-type').show()

    $('#save-dispute-button').addClass('hidden')
    $('#cancel-dispute-button').addClass('hidden')
    $('#related-dispute-input').addClass('hidden')
    $('#edit-dispute-button').removeClass('hidden')
    $('.dispute-edit-input').css('display','none')



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

window.disputes_select_all_check_box = () ->
  $('.dispute_check_box').prop('checked', $('#disputes_check_box').prop('checked'))

window.webrep_export_selected_rows = () ->
  checked_boxes = $('.dispute_check_box:checked').get()
  ids = checked_boxes.map (checkbox) -> parseInt(checkbox.value)

  query_string = '?'
  for id in ids
    query_string += "ids[]=#{id}&"

  window.open("/escalations/webrep/export_selected_dispute_rows#{query_string}", "_blank")

window.webrep_research_export_selected_rows = () ->
  checked_boxes = $('.dispute_check_box:checked').get()
  ids = checked_boxes.map (checkbox) -> parseInt(checkbox.getAttribute('data-entry-id'))

  query_string = '?'
  for id in ids
    query_string += "ids[]=#{id}&"

  window.open("/escalations/webrep/export_selected_dispute_entry_rows#{query_string}", "_blank")

$ ->
  $('#advanced-search-button').click ->
    $('#advanced-search-dropdown').show()

  $('#submit-advanced-search').click ->
    $('#search_name').val("")
    $('#advanced-search-dropdown').toggle()

  $(document).click ->
    $("#advanced-search-dropdown").hide()

  $(document).ready ->
    setInterval ->
      if window.current_search_data
        window.populate_webrep_index_table(window.current_search_data, true)
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


  window.averageTimeToCloseLabel = (hourAmount) ->
    totalSecond = hourAmount * 60 * 60
    seconds = totalSecond % 60
    totalMinutes = (totalSecond - seconds)/60
    minutes = totalMinutes % 60
    totalHours = (totalMinutes - minutes)/60
    hours = totalHours % 60
    value = ''
    if hours > 0
      value += hours + 'hr ' + minutes + 'm ' + seconds + 's'
    else if minutes > 0
      value += minutes + 'm ' + seconds + 's'
    else
      value += seconds + 's'
    return

# Create Dashboard Initial Table (My Open Tickets)
$ ->

#
  window.open_dashboard_dispute_table = $('#table-user-disputes-open').DataTable(
    dom: '<t>'
    paging: false
    columnDefs: [
      {
        targets: [ 1 ]
        className: 'id-col'
      }
      {
        targets: [ 3 ]
        className: 'state-col'
      }
      {
        targets: [
          0
          2
          4
        ]
        className: 'text-center'
      }
    ]
    columns: [
      {
        data: 'priority'
        render: (data) ->
          '<span class="esc-tooltipped bug-priority p-' + data + '" title="Priority ' + data + '"></span><span class="hidden-sortable-data">' + data + '</span>'
      }
      { data: 'case_link' }
      {
        data: 'submitter_type'
        render: (data) ->
          if (data) == 'customer'
            return '<span class="esc-tooltipped submitter-type-icon submitter-' + data + '" title="Customer"></span><span class="hidden-sortable-data">' + data + '</span>'
          else
            return '<span class="esc-tooltipped submitter-type-icon submitter-' + data + '" title="Guest"></span><span class="hidden-sortable-data">' + data + '</span>'
      }
      { data: 'status' }
      {
        data: 'submission_type'
        render: (data) ->
          if (data) == 'E'
            return '<span class="esc-tooltipped dispute-submission-type dispute-' + data  + '" title="Email"></span><span class="hidden-sortable-data">' + data + '</span>'
          else if (data) == 'W'
            return '<span class="esc-tooltipped dispute-submission-type dispute-' + data  + '" title="Web"></span><span class="hidden-sortable-data">' + data + '</span>'
          else if (data) == 'EW'
            return '<span class="esc-tooltipped dispute-submission-type dispute-' + data  + '" title="Email/Web"></span><span class="hidden-sortable-data">' + data + '</span>'
      }
      { data: 'd_entry_preview' }
      { data: 'last_comment' }
    ]
  )

  window.closed_dashboard_dispute_table = $('#table-user-disputes-closed').DataTable(
    dom: '<t>'
    paging: false
    columnDefs: [
      {
        targets: [ 1 ]
        className: 'id-col'
      }
      {
        targets: [
          0
          2
          3
        ]
        className: 'text-center'
      }
    ]
    columns: [
      {
        data: 'priority'
        render: (data) ->
          '<span class="esc-tooltipped bug-priority p-' + data + '" title="Priority ' + data + '"></span><span class="hidden-sortable-data">' + data + '</span>'
      }
      { data: 'case_link' }
      {
        data: 'submitter_type'
        render: (data) ->
          if (data) == 'customer'
            return '<span class="esc-tooltipped submitter-type-icon submitter-' + data + '" title="Customer"></span><span class="hidden-sortable-data">' + data + '</span>'
          else
            return '<span class="esc-tooltipped submitter-type-icon submitter-' + data + '" title="Guest"></span><span class="hidden-sortable-data">' + data + '</span>'
      }
      {
        data: 'submission_type'
        render: (data) ->
          if (data) == 'E'
            return '<span class="esc-tooltipped dispute-submission-type dispute-' + data  + '" title="Email"></span><span class="hidden-sortable-data">' + data + '</span>'
          else if (data) == 'W'
            return '<span class="esc-tooltipped dispute-submission-type dispute-' + data  + '" title="Web"></span><span class="hidden-sortable-data">' + data + '</span>'
          else if (data) == 'EW'
            return '<span class="esc-tooltipped dispute-submission-type dispute-' + data  + '" title="Email/Web"></span><span class="hidden-sortable-data">' + data + '</span>'
      }
      { data: 'd_entry_preview' }
      { data: 'time_to_close' }
    ]
  )

  window.open_multiuser_dashboard_dispute_table = $('#table-multi-user-disputes-open').DataTable(
    dom: '<t>'
    paging: false
    columnDefs: [
      {
        targets: [ 1 ]
        className: 'id-col'
      }
      {
        targets: [ 4 ]
        className: 'state-col'
      }
      {
        targets: [
          0
          2
          5
        ]
        className: 'text-center'
      }
    ]
    columns: [
      {
        data: 'priority'
        render: (data) ->
          '<span class="esc-tooltipped bug-priority p-' + data + '" title="Priority ' + data + '"></span><span class="hidden-sortable-data">' + data + '</span>'
      }
      { data: 'case_link' }
      {
        data: 'submitter_type'
        render: (data) ->
          if (data) == 'customer'
            return '<span class="esc-tooltipped submitter-type-icon submitter-' + data + '" title="Customer"></span><span class="hidden-sortable-data">' + data + '</span>'
          else
            return '<span class="esc-tooltipped submitter-type-icon submitter-' + data + '" title="Guest"></span><span class="hidden-sortable-data">' + data + '</span>'
      }
      { data: 'owner' }
      { data: 'status' }
      {
        data: 'submission_type'
        render: (data) ->
          if (data) == 'E'
            return '<span class="esc-tooltipped dispute-submission-type dispute-' + data  + '" title="Email"></span><span class="hidden-sortable-data">' + data + '</span>'
          else if (data) == 'W'
            return '<span class="esc-tooltipped dispute-submission-type dispute-' + data  + '" title="Web"></span><span class="hidden-sortable-data">' + data + '</span>'
          else if (data) == 'EW'
            return '<span class="esc-tooltipped dispute-submission-type dispute-' + data  + '" title="Email/Web"></span><span class="hidden-sortable-data">' + data + '</span>'
      }
      { data: 'd_entry_preview' }
      { data: 'last_comment' }
    ]
  )

  window.closed_dashboard_multiuser_dispute_table = $('#table-multi-user-disputes-closed').DataTable(
    dom: '<t>'
    paging: false
    columnDefs: [
      {
        targets: [ 1 ]
        className: 'id-col'
      }
      {
        targets: [
          0
          2
          4
        ]
        className: 'text-center'
      }
    ]
    columns: [
      {
        data: 'priority'
        render: (data) ->
          '<span class="esc-tooltipped bug-priority p-' + data + '" title="Priority ' + data + '"></span><span class="hidden-sortable-data">' + data + '</span>'
      }
      {
        data: 'case_link'
      }
      {
        data: 'submitter_type'
        render: (data) ->
          if (data) == 'customer'
            return '<span class="esc-tooltipped submitter-type-icon submitter-' + data + '" title="Customer"></span><span class="hidden-sortable-data">' + data + '</span>'
          else
            return '<span class="esc-tooltipped submitter-type-icon submitter-' + data + '" title="Guest"></span><span class="hidden-sortable-data">' + data + '</span>'
      }
      {
        data: 'owner'
      }
      {
        data: 'submission_type'
        render: (data) ->
          if (data) == 'E'
            return '<span class="esc-tooltipped dispute-submission-type dispute-' + data  + '" title="Email"></span><span class="hidden-sortable-data">' + data + '</span>'
          else if (data) == 'W'
            return '<span class="esc-tooltipped dispute-submission-type dispute-' + data  + '" title="Web"></span><span class="hidden-sortable-data">' + data + '</span>'
          else if (data) == 'EW'
            return '<span class="esc-tooltipped dispute-submission-type dispute-' + data  + '" title="Email/Web"></span><span class="hidden-sortable-data">' + data + '</span>'
      }
      { data: 'd_entry_preview' }
      { data: 'time_to_close' }
    ]
  )




$ ->
# Toggle which rows to show on tables
  show_ticket_type_cb = $('.show-tickets-cb')

  $(show_ticket_type_cb).click ->
#    Need to traverse to toolbar wrapper and get the sibling wrappers for the tables
    toolbar_wrapper = $(this).parents('.toolbar')
    table_wrappers = $(toolbar_wrapper[0]).siblings('.tickets-section-wrapper')
    ticket_tables = $(table_wrappers).find('.dashboard-tickets-table')

    all_tickets_rows = []
    customer_rows = []
    guest_rows = []
    c_e_rows = []
    c_w_rows = []
    c_ew_rows = []
    g_e_rows = []
    g_w_rows = []
    g_ew_rows = []

    show_email_cb = $(toolbar_wrapper).find('.tickets-show-email-cb')
    show_web_cb = $(toolbar_wrapper).find('.tickets-show-web-cb')
    show_emailweb_cb = $(toolbar_wrapper).find('.tickets-show-email-web-cb')
    show_customer_cb = $(toolbar_wrapper).find('.tickets-show-customer-cb')
    show_guests_cb = $(toolbar_wrapper).find('.tickets-show-guest-cb')

    $(ticket_tables).each ->
      row = $(this).find('tr')
      $(row).each ->
        all_tickets_rows.push this

    $(all_tickets_rows).each ->
      parent_row = this
      submitter_type = $(this).find('.submitter-type-icon')
      if $(submitter_type).hasClass('submitter-customer')
        customer_rows.push parent_row
      if $(submitter_type).hasClass('submitter-non-customer')
        guest_rows.push parent_row

    $(customer_rows).each ->
      ticket_type = $(this).find('.dispute-submission-type')
      if $(ticket_type).hasClass('dispute-E')
        c_e_rows.push this
      if $(ticket_type).hasClass('dispute-W')
        c_w_rows.push this
      if $(ticket_type).hasClass('dispute-EW')
        c_ew_rows.push this

    $(guest_rows).each ->
      ticket_type = $(this).find('.dispute-submission-type')
      if $(ticket_type).hasClass('dispute-E')
        g_e_rows.push this
      if $(ticket_type).hasClass('dispute-W')
        g_w_rows.push this
      if $(ticket_type).hasClass('dispute-EW')
        g_ew_rows.push this


    if this == show_customer_cb[0]
      if this.checked
        if show_email_cb[0].checked
          $(c_e_rows).each ->
            if $(this).hasClass('hidden')
              $(this).removeClass('hidden')
        else
          $(c_e_rows).each ->
            unless $(this).hasClass('hidden')
              $(this).addClass('hidden')
        if show_web_cb[0].checked
          $(c_w_rows).each ->
            if $(this).hasClass('hidden')
              $(this).removeClass('hidden')
        else
          $(c_w_rows).each ->
            unless $(this).hasClass('hidden')
              $(this).addClass('hidden')
        if show_emailweb_cb[0].checked
          $(c_ew_rows).each ->
            if $(this).hasClass('hidden')
              $(this).removeClass('hidden')
        else
          $(c_ew_rows).each ->
            unless $(this).hasClass('hidden')
              $(this).addClass('hidden')
      else
        $(customer_rows).each ->
          unless $(this).hasClass('hidden')
            $(this).addClass('hidden')

    if this == show_guests_cb[0]
      if this.checked
        if show_email_cb[0].checked
          $(g_e_rows).each ->
            if $(this).hasClass('hidden')
              $(this).removeClass('hidden')
        else
          $(g_e_rows).each ->
            unless $(this).hasClass('hidden')
              $(this).addClass('hidden')
        if show_web_cb[0].checked
          $(g_w_rows).each ->
            if $(this).hasClass('hidden')
              $(this).removeClass('hidden')
        else
          $(g_w_rows).each ->
            unless $(this).hasClass('hidden')
              $(this).addClass('hidden')
        if show_emailweb_cb[0].checked
          $(g_ew_rows).each ->
            if $(this).hasClass('hidden')
              $(this).removeClass('hidden')
        else
          $(g_ew_rows).each ->
            unless $(this).hasClass('hidden')
              $(this).addClass('hidden')
      else
        $(guest_rows).each ->
          unless $(this).hasClass('hidden')
            $(this).addClass('hidden')

    if this == show_email_cb[0]
      if this.checked
        if show_customer_cb[0].checked
          $(c_e_rows).each ->
            if $(this).hasClass('hidden')
              $(this).removeClass('hidden')
        else
          $(c_e_rows).each ->
            unless $(this).hasClass('hidden')
              $(this).addClass('hidden')
        if show_guests_cb[0].checked
          $(g_e_rows).each ->
            if $(this).hasClass('hidden')
              $(this).removeClass('hidden')
        else
          $(g_e_rows).each ->
            unless $(this).hasClass('hidden')
              $(this).addClass('hidden')
      else
        $(c_e_rows).each ->
          unless $(this).hasClass('hidden')
            $(this).addClass('hidden')
        $(g_e_rows).each ->
          unless $(this).hasClass('hidden')
            $(this).addClass('hidden')

    if this == show_web_cb[0]
      if this.checked
        if show_customer_cb[0].checked
          $(c_w_rows).each ->
            if $(this).hasClass('hidden')
              $(this).removeClass('hidden')
        else
          $(c_w_rows).each ->
            unless $(this).hasClass('hidden')
              $(this).addClass('hidden')
        if show_guests_cb[0].checked
          $(g_w_rows).each ->
            if $(this).hasClass('hidden')
              $(this).removeClass('hidden')
        else
          $(g_w_rows).each ->
            unless $(this).hasClass('hidden')
              $(this).addClass('hidden')
      else
        $(c_w_rows).each ->
          unless $(this).hasClass('hidden')
            $(this).addClass('hidden')
        $(g_w_rows).each ->
          unless $(this).hasClass('hidden')
            $(this).addClass('hidden')

    if this == show_emailweb_cb[0]
      if this.checked
        if show_customer_cb[0].checked
          $(c_ew_rows).each ->
            if $(this).hasClass('hidden')
              $(this).removeClass('hidden')
        else
          $(c_ew_rows).each ->
            unless $(this).hasClass('hidden')
              $(this).addClass('hidden')
        if show_guests_cb[0].checked
          $(g_ew_rows).each ->
            if $(this).hasClass('hidden')
              $(this).removeClass('hidden')
        else
          $(g_ew_rows).each ->
            unless $(this).hasClass('hidden')
              $(this).addClass('hidden')
      else
        $(c_ew_rows).each ->
          unless $(this).hasClass('hidden')
            $(this).addClass('hidden')
        $(g_ew_rows).each ->
          unless $(this).hasClass('hidden')
            $(this).addClass('hidden')
