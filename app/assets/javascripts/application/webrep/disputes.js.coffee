$(document).ready ->
  Chart.defaults.global.plugins.datalabels.display = false
  $('span#mark-as-related').on 'show.bs.dropdown', ->
    if $('.dispute_check_box:checked').length == 0
      std_msg_error('No rows selected', ['Please select at least one row.'])
      return false

  if ($('.searched-for-url').length > 0) && location.hash != "#lookup-quick"
      text = $('.searched-for-url').text().trim().split(/\s+/)
      if (text.length > 1)
        if (text.length == 2)
          text = text.join(', ').replace(/, /, ' and ')
        else if (text.length > 2)
          text = text.join(', ').replace(/, ([^,]*)$/, ', and $1')
        text = text.replace(/(, and| and |, )/g, '<span class="unset-text">$1</span>')
        return $('.searched-for-url').html(text)

  if window.location.pathname == '/escalations/webrep/disputes'
    std_msg_ajax(
      method: 'POST'
      url: "/escalations/api/v1/escalations/user_preferences/"
      data: {name: 'WebRepColumns'}
      success: (response) ->
        response = JSON.parse(response)
        if response?
          $.each response, (column, state) ->
            if state == true
              $("##{column}-checkbox").prop('checked', true)
              window.dispute_table.column("##{column}").visible true
            else
              $("##{column}-checkbox").prop('checked', false)
              window.dispute_table.column("##{column}").visible false
  )
  $('.toggle-vis').click ->
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
    data['last-updated'] = $("#last-updated-checkbox").is(':checked')
    data['platform'] = $("#platform-checkbox").is(':checked')
    std_msg_ajax(
      url: "/escalations/api/v1/escalations/user_preferences/update"
      method: 'POST'
      data: {data, name: 'WebRepColumns'}
      dataType: 'json'
      success: (response) ->
    )

  $('.toggle-vis-nested').click ->
    data = {}
    data['dispute-entry'] = $("#dispute-entry-checkbox").is(':checked')
    data['entry-status'] = $("#entry-status-checkbox").is(':checked')
    data['entry-resolution'] = $("#entry-resolution-checkbox").is(':checked')
    data['suggested-disposition'] = $("#suggested-disposition-checkbox").is(':checked')
    data['category'] = $("#category-checkbox").is(':checked')
    data['platform-entry'] = $("#platform-entry-checkbox").is(':checked')
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

window.select_or_deselect_all = (dispute_id)->

  $('.dispute-entry-checkbox_' + dispute_id).prop('checked', $('#' + dispute_id).prop('checked'))
  $('.dispute-entry-checkbox_' + dispute_id).each ->
    toggleRow(this)


window.advanced_webrep_index_table = () ->
  form = $('#disputes-advanced-search-form')
  dispute_save_search_format = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/
  data = {
    search : {
      value: null
      regex: false
    }
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
    submitter_type: form.find('input[id="submitter-input"]').val()
    platform_names: form.find('input[id="platform-input"]').val()
    submitted_older: form.find('input[id="submitted-older-input"]').val()
    submitted_newer: form.find('input[id="submitted-newer-input"]').val()
    age_older: form.find('input[id="age-older-input"]').val()
    age_newer: form.find('input[id="age-newer-input"]').val()
    modified_older: form.find('input[id="modified-older-input"]').val()
    modified_newer: form.find('input[id="modified-newer-input"]').val()
    case_origin: form.find('input[id="case-origin-input"]').val()
  }
  unless form.find('#submission-type').parent().hasClass('hidden')
    submission_types = []
    if form.find('input#submission-type-w-cb').is(':checked')
      submission_types.push('w')
    if form.find('input#submission-type-e-cb').is(':checked')
      submission_types.push('e')
    if form.find('input#submission-type-ew-cb').is(':checked')
      submission_types.push('ew')
    data['submission_type'] = submission_types


  if dispute_save_search_format.test(data.search_name) == true
    std_msg_error('save search name error', ['Please enter a name without any special character', 'Example: !@#$%^&*()'])
  else
    localStorage.webRepFilters = JSON.stringify(data)
    refresh_webrep_url()

window.refresh_webrep_url = (href) ->
  url_check = window.location.href.split('/escalations/webrep/disputes/')[0]
  new_url = '/escalations/webrep/disputes'

  if href != undefined
    localStorage.setItem('webrep_search_name', href)
    window.location.replace(new_url + href)

  if !href && typeof parseInt(url_check) == 'number'
    window.location.replace('/escalations/webrep/disputes')

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
  localStorage.webRepFilters = JSON.stringify(data)
  refresh_webrep_url()

window.call_contains_search = (search_form) ->
  localStorage.removeItem('webRepFilters')
  search_value = search_form.querySelector('input.search-box').value.trim()
  search_value = search_value.replace(/^0+/, '')   # remove extraneous leading zeroes if they exist, example: "000123"

  data = {
    search_type: 'contains'
    value: search_value
  }
  localStorage.webRepFilters = JSON.stringify(data)
  refresh_webrep_url()


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
      show_message('success', 'Ticket assignment has been updated!', 5)
      window.location.reload()
    error: (response) ->
      show_message('error', 'Ticket assignment could not be updated.', 5)
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
      $('.take-dispute-' + dispute_id).replaceWith("<button class='esc-tooltipped return-ticket-button return-ticket-#{dispute_id}' title='Assign this ticket to me' onclick='return_dispute(#{dispute_id});'></button>")
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
        'Due to: ' + error.responseJSON.message
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
    success: (response) ->
      if response.dispute_ids.length > 0
        show_message('success', 'Ticket assignment has been updated!', 5)
        location.reload()
      else
        show_message('error', 'Ticket assnigment could not be updated.', 5)
        location.reload()
  )

window.return_dispute = (dispute_id) ->
  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/webrep/disputes/return_dispute/" + dispute_id
    data: {}
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      $('.return-ticket-' + dispute_id).replaceWith("<button class='esc-tooltipped take-ticket-button take-dispute-#{dispute_id}' title='Assign this ticket to me' onclick='take_dispute(#{dispute_id});'></button>")
      $('#owner_' + response.dispute_id).text('Unassigned')
      $('#status_' + response.dispute_id).text('NEW')

  )

window.save_dispute_entries = () ->
  data = {}
  changes_made = false
  $('#disputes-research-table').find('tr.research-table-row').each(() ->
    $(this).find('.dual-edit-field').map(() ->
      {id, field} = this.dataset
      if field != 'host-ip'
        # host-ip is changing is handled separately
        if data[id] == undefined then data[id] = []
        switch field
          when 'status'
            if $(this).find("input[name='entry-status']:checked").attr('id') == undefined
              new_value = $(this).find(".table-entry-input")[0].innerHTML.trim()
            else
              new_value = $(this).find("input[name='entry-status']:checked").attr('id')
          when 'host'
            new_value = $(this).find('.table-entry-input').val()

        old_value = $(this).find('.entry-data')[0].innerText.trim()

        if new_value == undefined then new_value = old_value

        if new_value != old_value
          changes_made = true
          if new_value == "RESOLVED_CLOSED"
            resolution_data = {
              id: id
              field: "resolution"
              new: $('input[name=entry-resolution]:checked').attr('id')
            }
            resolution_comment = {
              id: id
              field: "resolution_comment"
              new: $(this).find("textarea[name='resolution-comment']")[0].value
            }
            data[id].push(resolution_data)
            data[id].push(resolution_comment)

          else
            new_data = {
              id: id,
              field: field,
              old: old_value
              new: new_value}
            data[id].push( new_data )
    )
  )
  if !changes_made
    std_msg_error('No changes made', [])
  else
    if $('input[name=entry-status]:checked').attr('id') == "RESOLVED_CLOSED" && !$('input[name=entry-resolution]:checked').val()
      std_msg_error('No resolution selected', ['Please select a ticket resolution.'])
    else
      std_msg_ajax(
        method: 'PATCH'
        url: "/escalations/api/v1/escalations/webrep/disputes/entries/field_data"
        data: { 'field_data': data }
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
  successfully_closed_disputes = []

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

  for dispute, dispute_index in checked_disputes
#    event.preventDefault()
    data.dispute_ids = [dispute]
    top_index = checked_disputes.length - 1

    $.ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/set_disputes_status'
      method: 'POST'
      headers: headers
      data: data
      mimeType: 'application/json'
      async: false
      success: (response) ->

        if status != 'RESOLVED_CLOSED'
         window.location.reload()
        else
          #show Close Tickets modal when the last query is returned
          successfully_closed_disputes.push dispute
          if dispute_index == top_index
            show_close_tickets_modal(successfully_closed_disputes)

      error: (response) ->
        if response.status > 400
          popup_response_error(response, 'Error Updating Status')
  )

window.show_close_tickets_modal = (checked_disputes) ->

  $('#close-ticket-modal').modal('show')
  url = '/escalations/webrep/disputes/'
  list_wrapper = $('#close-ticket-modal').find('#closed-tickets-id-list')[0]

  $(checked_disputes).each (i, dispute) ->
    dispute_trimmed = dispute.replace(/^0+/, '')
    full_link = url + dispute_trimmed
    dispute_link = "<li><a target='_blank' href=#{full_link}>#{dispute}</a></li>"
    $(list_wrapper).append dispute_link

  $('#close-ticket-modal').on('hidden.bs.modal', ->
    window.location.reload()
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

  #clear selectize fields
  $("#platform-input")[0].selectize.clear()
  $("#status-input")[0].selectize.clear()
  $("#priority-input")[0].selectize.clear()
  $("#resolution-input")[0].selectize.clear()

window.clearSelectize = (input) ->
  $("##{input}")[0].selectize.clear()

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
  window.dispute_table = $('#disputes-index').on(
    'preXhr.dt': ->
      $('#inline-webrep').removeClass('hidden')).DataTable(
    pagingType: 'full_numbers'
    processing: true
    serverSide: true
    ajax:
      url: '/escalations/api/v1/escalations/webrep/disputes'
      method: 'GET'
      headers: {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
      data: build_webrep_data()
      complete: () ->
        #cache current filters for export_all form
        $('#disputes-index-export-data-input').val(JSON.stringify(build_webrep_data()))
        $('#inline-webrep').addClass('hidden')
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
        targets: [ 7 ]
        className: 'dispute-entry-col'
      }
      {
        targets: [ 8 ]
        className: 'owner-col'
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
      { data: 'dispute_resolution' }
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
      {
        data: 'd_entry_preview'
        render: (data) ->
          # data here is an html string with a span for count, see models/dispute.rb for details, extract the text for the tooltip
          tooltip_text = data.slice(0, data.indexOf('<span'))
          '<span class="input-truncate esc-tooltipped" title="' + tooltip_text + '">' + data + '</span>'
      }
      { data: 'assigned_to' }
      { data: 'case_opened_at' }
      {
        data: 'case_age'
        'render': (data,type,full,meta) ->
          if data != "<1 hr"
            dispute_duration = moment(full.case_opened_at).fromNow()
            if dispute_duration.includes('minute')
              dispute_latency = data
            if dispute_duration.includes('hour')
              hours = parseInt(dispute_duration.replace(/[^0-9]/g, ''))
              if hours <= 18
                dispute_latency = data
              else
                dispute_latency = '<span class="ticket-age-over18hr">' + data + '</span>'
            else
              dispute_latency = '<span class="ticket-age-over18hr">' + data + '</span>'
            if dispute_duration.includes('day')
              day = parseInt(data.replace(/[^0-9]/g, ''))
              if day >= 1
                dispute_latency = '<span class="ticket-age-over18hr">' + data + '</span>'
            if dispute_duration.includes('months')
              month = parseInt(data.replace(/[^0-9]/g, ''))
              dispute_latency = '<span class="ticket-age-over18hr">' + data + '</span>'
            if dispute_duration.includes('year')
              year = parseInt(data.replace(/[^0-9]/g, ''))
              dispute_latency = '<span class="ticket-age-over18hr">' + data + '</span>'
            dispute_latency
          else
            data
      }
      { data: 'source' }
      {
        data: 'platform'
        orderable: false
        class: 'platform-col'
        render: (data,type,full,meta) ->
          platform = full.platform

          if  platform == "N/A" ||  platform == "Unknown" ||  platform == "Missing" ||  platform == "" ||  platform == null
            platform = '<span class="missing-data platform"></span>'
          return  platform
      }
      { data: 'submitter_type'}
      { data: 'submitter_org' }
      { data: 'submitter_domain' }
      { data: 'submitter_name' }
      { data: 'submitter_email' }
      { data: 'status_comment' }
      { data: 'updated_at' }
      {
        data: 'age_int'
        visible: false
      }
    ])
  $('#disputes-index_filter input').addClass('table-search-input');

  window.format = (dispute) ->
    table_head =
      "<table class='table dispute-entry-table'><thead><tr>
       <th><input class='dispute_entry_select_all' type='checkbox' onclick='select_or_deselect_all(#{dispute.id})' id='#{dispute.id}' /></th>
       <th class='entry-col-content'>Dispute Entry</th>
       <th class='entry-col-status'>Dispute Entry Status</th>
       <th class='entry-col-res'>Dispute Entry Resolution</th>
       <th class='entry-col-disp'>Suggested Disposition</th>
       <th class='entry-col-cat'>Category</th>
       <th class='entry-col-platform-entry'>Platform</th>
       <th class='entry-col-wbrs-score'>WBRS Score</th>
       <th class='entry-col-wbrs-hits'>WBRS Total Rule Hits</th>
       <th class='entry-col-wbrs-rules'>WBRS Rules</th>
       <th class='entry-col-sbrs-score'>SBRS Score</th>
       <th class='entry-col-sbrs-hits'>SBRS Total Rule Hits</th>
       <th class='entry-col-sbrs-rules'>SBRS Rules</th></tr></thead><tbody>"
    entry = JSON.parse(dispute.dispute_entries.replace(/&quot;/g,'"').replace(/=&gt;/g, ':'))
    missing_data = '<span class="missing-data">Missing data</span>'
    entry_rows = []
    $(entry).each ->
      {ip_address, uri, primary_category} = this.entry
      platform = this.rendered_platform
      entry_content = missing_data
      if ip_address != null
        entry_content = ip_address
      else if uri != null
        entry_content = uri
      category = '<span class="missing-data">No assigned categories</span>'
      if this.entry.primary_category != null && this.entry.primary_category != '{}'
        category = this.entry.primary_category

      if platform == null
        platform = "<span class='missing-data'>No platform</span>"

      status = missing_data
      if this.entry.status != null
        status = this.entry.status

      resolution = missing_data
      if this.entry.resolution != null
        resolution = this.entry.resolution

      if this.entry.resolution_comment != null
        resolution_comment = this.entry.resolution_comment
        resolution_col = "<td class='entry-col-res'>#{resolution_comment}</td>"
      else
        resolution_comment = ''
        resolution_col = "<td class='entry-col-res'>#{resolution}</td>"

      suggested_disposition = ''
      if this.entry.suggested_disposition != null
        suggested_disposition = this.entry.suggested_disposition

      if this.entry.is_important == true
        important = 'entry-important-flag'
      else
        important = ''
      if this.entry.was_dismissed
        important = important + ' entry-was-dismissed-flag'
      dispute_entry_id = this.entry.id
      if this.entry.wbrs_score != null
        wbrs_score = this.entry.wbrs_score
        rep = wbrs_display(wbrs_score)
        wbrs_score = parseFloat(wbrs_score).toFixed(1)
        if wbrs_score == NaN then wbrs_score = '--'
        tooltip_rep = rep.toUpperCase()
      else
        rep = 'unknown'
        tooltip_rep = rep.toUpperCase()
        wbrs_score = '--'

      if this.entry.sbrs_score != null
        sbrs_score = this.entry.sbrs_score
      else
        sbrs_score = missing_data

      entry_row = "<tr class='index-entry-row' data-case-id='0000#{dispute.id}'>
        <td>
          <input type='checkbox' onclick='toggleRow(this)' class='dispute-entry-checkbox dispute-entry-checkbox_#{dispute.id}' id='#{dispute_entry_id}'>
        </td>
        <td class='entry-col-content #{important}'> #{entry_content}</td>
        <td class='entry-col-status'>#{status}</td>
        #{resolution_col}
        <td class='entry-col-disp'>#{suggested_disposition}</td>
        <td class='entry-col-cat'>#{category}</td>
        <td class='entry-col-platform-entry'>#{platform}</td>
        <td class='entry-col-wbrs-score'>
          <div class='reputation-icon-container'>
            <span class='reputation-icon icon-#{rep} esc-tooltipped' title='#{tooltip_rep}'></span>
            <span>#{wbrs_score}</span>
          <div>
        </td>
        <td class='entry-col-wbrs-hits'> #{this.wbrs_rule_hits.length}</td>
        <td class='entry-col-wbrs-rules'>#{this.wbrs_rule_hits.join(', ')}</td>
        <td class='entry-col-sbrs-score'>#{sbrs_score}</td>
        <td class='entry-col-sbrs-hits'>#{this.sbrs_rule_hits.length}</td>
        <td class='entry-col-sbrs-rules'>#{this.sbrs_rule_hits.join(', ')}</td>
        </tr>"
      entry_rows.push entry_row
      return
    # `d` is the original data object for the row
    table_head + entry_rows.join('') + '</tbody></table>'

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

      # subrow icons need the TT init on row expand, these icons don't exist on dt draw.dt, init them here
      $('#disputes-index .reputation-icon').tooltipster
        theme: [
          'tooltipster-borderless'
          'tooltipster-borderless-customized'
        ]

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
  $('#disputes-index').DataTable().on 'length.dt', (e, settings, len) ->
    data = {}
    data['entriesperpage'] = $('select[name="disputes-index_length"]').val()
    std_msg_ajax(
      url: "/escalations/api/v1/escalations/user_preferences/update"
      method: 'POST'
      data: {data, name: 'WebRepEntriesPerPage'}
      dataType: 'json'
      success: (response) ->
    )

  $('#new-dispute').click ->
    std_msg_ajax(
      method: 'GET'
      url: '/escalations/api/v1/escalations/webrep/disputes/populate_new_dispute_fields'
      success: (response) ->
        for user in response.json.assignees
          $('#assignee-list').append '<option value=\'' + user.cvs_username + '\'></option>'
    )


  $('#disputes-index th').on "click", ->
    setTimeout (-> # Wait until after the sorting event is finished before saving the result
      data = {}
      data['sortorder'] = $('#disputes-index').DataTable().order()
      std_msg_ajax(
        url: "/escalations/api/v1/escalations/user_preferences/update"
        method: 'POST'
        data: {data, name: 'WebRepSortOrder'}
        dataType: 'json'
        success: (response) ->
      )
    ), 100


  $('#disputes-index_paginate').on "click", ->
    data = {}
    data['currentpage'] = $('#disputes-index').DataTable().page()
    std_msg_ajax(
      url: "/escalations/api/v1/escalations/user_preferences/update"
      method: 'POST'
      data: {data, name: 'WebRepCurrentPage'}
      dataType: 'json'
      success: (response) ->
    )

  $('#webrep-advanced-search-button').click ->
    # if we have already loaded the advanced search, with all options no need to load it again
    if $('#company-list').find('option').size() == 0

      if localStorage.getItem('webRepFilters') != null
        filter_data_found = false
        #populate any non-selectize fields with current filters
        #note: any selectize filters need to be populated after the selectize options are created
        filters = JSON.parse(localStorage.webRepFilters)

        #Need to check if this a saved or basic search, since those don't load in the data to the local storage
        if filters.search_type != 'named' && filters.search_type != 'contains' && $('#dispute-advaced-search-selected-filters').html() != ''
          filter_data_found = true

          #Case ID field
          $('#caseid-input').val filters.case_id
          #Dispute (URL/IP/Domain)
          $('#dispute-input').val filters.dispute_entries.ip_or_uri
          #Assignee
          $('#owner-input').val filters.case_owner_username
          #Suggested Disposition
          $('#disposition-input').val filters.dispute_entries.suggested_disposition
          #Submitter Type
          $('#submitter-input').val filters.submitter_type
          #Contact Name
          $('#name-input').val filters.customer.name
          #Contact Email
          $('#email-input').val filters.customer.email
          #Submitter Org
          $('#company-input').val filters.customer.company_name
          #Submitter Domain
          $('#domain-input').val filters.org_domain
          #Date Submitted (Newer)
          $('#submitted-newer-input').val filters.submitted_newer
          #Date Submitted (Older)
          $('#submitted-older-input').val filters.submitted_older
          #Case Origin
          $('#case-origin-input').val filters.case_origin
          #Case Age (Newer) ex: 30d 12h
          $('#age-newer-input').val filters.age_newer
          #Case Age (Older) ex: 7d 12h
          $('#age-older-input').val filters.age_older
          #Last Modified (Newer)
          $('#modified-newer-input').val filters.modified_newer
          #Last Modified (Older)
          $('#modified-older-input').val filters.modified_older

          #check for submission types parameter - if field is hidden there is no .submission_type attached
          if filters.submission_type?
            #uncheck any Submission Types that are not included in filters
            if filters.submission_type.includes('w') == false
              $('#submission-type-w-cb').prop('checked', false)

            if filters.submission_type.includes('ew') == false
              $('#submission-type-ew-cb').prop('checked', false)

            if filters.submission_type.includes('e') == false
              $('#submission-type-e-cb').prop('checked', false)

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
          $('#case-origin-list').empty()

          $('#platform-input').selectize {
            persist: false
            create: false
            valueField: 'id',
            labelField: 'public_name',
            options: response.json.platforms
            onFocus: () ->
              window.toggle_selectize_layer(this, 'true')
            onBlur: () ->
              window.toggle_selectize_layer(this, 'false')
          }

          $('#resolution-input').selectize {
            persist: false
            create: false
            valueField: 'id',
            labelField: 'public_name',
            options: response.json.resolutions
            onFocus: () ->
              window.toggle_selectize_layer(this, 'true')
            onBlur: () ->
              window.toggle_selectize_layer(this, 'false')
          }

          $('#status-input').selectize {
            persist: false
            create: false
            valueField: 'id',
            labelField: 'public_name',
            options: response.json.statuses
            onFocus: () ->
              window.toggle_selectize_layer(this, 'true')
            onBlur: () ->
              window.toggle_selectize_layer(this, 'false')
          }

          $('#priority-input').selectize {
            persist: false
            create: false
            valueField: 'id',
            labelField: 'public_name',
            options: response.json.priorities
            onFocus: () ->
              window.toggle_selectize_layer(this, 'true')
            onBlur: () ->
              window.toggle_selectize_layer(this, 'false')
          }

          #populate selectize fields if correct localstorage is found
          if filter_data_found == true

            #populate platform
            if filters.platform_names != ''
              platform_input = $('#platform-input').selectize()
              platform_names = filters.platform_names.split(',')
              platform_input[0].selectize.setValue(platform_names)

            #populate resolution
            if filters.resolution != ''
              resolution_input = $('#resolution-input').selectize()
              resolutions = filters.resolution.split(',')
              resolution_input[0].selectize.setValue(resolutions)

            #populate status
            if filters.status != ''
              status_input = $('#status-input').selectize()
              statuses = filters.status.split(',')
              status_input[0].selectize.setValue(statuses)

            #populate priority
            if filters.priority != ''
              priority_input = $('#priority-input').selectize()
              priorities = filters.priority.split(',')
              priority_input[0].selectize.setValue(priorities)

          for user in response.json.case_owners
            $('#user-list').append '<option value=\'' + user + '\'></option>'

          for type in response.json.submitter_types
            $('#submittertype-list').append '<option value=\'' + type + '\'></option>'

          for contact in response.json.contacts
            $('#contactname-list').append '<option value=\'' + contact.name + '\'></option>'

          for contact in response.json.contacts
            $('#contactemail-list').append '<option value=\'' + contact.email + '\'></option>'

          for company in response.json.companies
            $('#company-list').append '<option value=\'' + company + '\'></option>'

          for source in response.json.sources
            $('#case-origin-list').append '<option value=\'' + source + '\'></option>'

      )



    if window.location.pathname.includes('/escalations/file_rep') ||  window.location.pathname.includes('/escalations/webrep')
      $('#filter-cases').show()
      $('#import-webrep').show()
    #      $('#web-rep-search').show()
    else
      $('#filter-cases').hide()
      $('#import-webrep').hide()
  #      $('#web-rep-search').hide()

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


  $('#webrep-resolution-selector input[type=radio][name=dispute-resolution]').change (event)->
    submission_type = $('input[name=webrep-dispute-submission-type').val()
    submitter_type = $('input[name=webrep-dispute-submitter-type]').val()
    #Only fill comment if web type submission
    if submission_type == 'w' && submitter_type != "INTERNAl"
      if submitter_type == 'CUSTOMER'
        is_customer = true

      $(".ticket-resolution-comment").html('')
      messageId = $(event.target).data('id')
      resolution_comment = get_resolution_comment(@value, is_customer, messageId)
      $(".ticket-resolution-comment").html(resolution_comment)


  $('#webrep-entry-resolution-selector input[type=radio][name=entry-resolution]').change (event)->
    submission_type = $('input[name=webrep-dispute-submission-type').val()
    submitter_type = $('input[name=webrep-dispute-submitter-type]').val()
    #Only fill comment if web type submission
    if submission_type == 'w' && submitter_type != "INTERNAl"
      if submitter_type == 'CUSTOMER'
        is_customer = true
      $('#webrep-entry-resolution-comment').html('')
      messageId = $(event.target).data('id')
      resolution_comment = get_resolution_comment(@value, is_customer, messageId)
      $("#webrep-entry-resolution-comment").html(resolution_comment)


  $('#index-ticket-resolution-submenu input[type=radio][name=ticket-resolution]').change (event)->
    $(".ticket-status-comment").html('')
    submission_types = []
    submitter_types = []
    checkboxes = $('#disputes-index').find('.dispute_check_box')
    $(checkboxes).each ->
      if $(this).is(':checked')
        tr = $(this).closest('tr')
        row = window.dispute_table.row(tr)
        submission_types.push(row.data().submission_type)
        submitter_types.push(row.data().submitter_type)

    submission_types.sort()
    submitter_types.sort()

    common_submission = (submission_types[0] == submission_types[submission_types.length - 1])
    common_submitter = (submitter_types[0] == submitter_types[submitter_types.length - 1])

    if common_submission && common_submitter
      submission_type = submission_types[0]
      submitter_type = submitter_types[0]

      if submission_type == 'w' && submitter_type != 'INTERNAl'
        if submitter_type == 'CUSTOMER'
          is_customer = true
        messageId = $(event.target).data('id')
        resolution_comment = get_resolution_comment(@value, is_customer, messageId)
        $(".ticket-status-comment").html(resolution_comment)

  $('#index-entry-resolution-submenu input[type=radio][name=entry-resolution]').change (event)->
    $("#entry-status-comment").html('')
    checkboxes = $('#disputes-index').find('.dispute-entry-checkbox')
    submission_types = []
    submitter_types = []
    checkboxes.each ->
      if $(this).is(':checked')
        wrapper = $(this)[0].closest('.dispute-entry-table-wrapper')
        entry_row = wrapper.parentElement
        ticket_row = entry_row.previousSibling
        row = window.dispute_table.row(ticket_row)
        submission_types.push(row.data().submission_type)
        submitter_types.push(row.data().submitter_type)

    submission_types.sort()
    submitter_types.sort()

    common_submission = (submission_types[0] == submission_types[submission_types.length - 1])
    common_submitter = (submitter_types[0] == submitter_types[submitter_types.length - 1])

    if common_submission && common_submitter
      submission_type = submission_types[0]
      submitter_type = submitter_types[0]

      if submission_type == 'w' && submitter_type != 'INTERNAl'
        if submitter_type == 'CUSTOMER'
          is_customer = true
        messageId = $(event.target).data('id')
        resolution_comment = get_resolution_comment(@value, is_customer, messageId)
        $("#entry-status-comment").html(resolution_comment)

window.get_resolution_comment = (value, is_customer, messageId) ->
  resolutionMessage = getResolutionMessageTemplate(messageId)
  if resolutionMessage.description == 'UNCHANGED'
    return resolutionMessage.body + " Please open a TAC case and provide additional details if you need further assistance."
  return resolutionMessage.body

window.getResolutionMessageTemplate = (messageId)->
  message = null
  std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/webrep/resolution_message_templates/#{messageId}"
      success_reload: false
      async: false
      success: (response) ->
        message = response
  )
  message
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
  row = $('.dispute_check_box').parents('tr')
  if $('.dispute_check_box').prop('checked') == true
    $(row).addClass('selected')
  else
    $(row).removeClass('selected')

window.webrep_export_selected_rows = () ->
  checked_boxes = $('.dispute_check_box:checked').get()

  if checked_boxes.length > 0
    ids = checked_boxes.map (checkbox) -> parseInt(checkbox.value)

    query_string = '?'
    for id in ids
      query_string += "ids[]=#{id}&"

    window.open("/escalations/webrep/export_selected_dispute_rows#{query_string}", "_blank")
  else
    std_msg_error('Error',['Please select at least one row before exporting'])

window.webrep_research_export_selected_rows = () ->
  checked_boxes = $('.dispute_check_box:checked').get()

  if checked_boxes.length > 0
    ids = checked_boxes.map (checkbox) -> parseInt(checkbox.getAttribute('data-entry-id'))

    query_string = '?'
    for id in ids
      query_string += "ids[]=#{id}&"

    window.open("/escalations/webrep/export_selected_dispute_entry_rows#{query_string}", "_blank")
  else
    std_msg_error('Error',['Please select at least one row before exporting'])

window.get_threat_categories = (uri) ->
  data = {'uri': uri}
  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/threat_categories'
    method: 'POST'
    data: data
    success: (response) ->
      return response
  )

window.get_threat_levels = (uri) ->
  data = {'uri': uri}
  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/threat_levels'
    method: 'POST'
    data: data
    success: (response) ->
      return response
  )

$ ->
  $('#webrep-advanced-search-button').click ->
    $('#advanced-search-dropdown').show()

  $('#submit-advanced-search').click ->
    $('#search_name').val("")
    $('#advanced-search-dropdown').toggle()

  $('.esc-tooltipped').tooltipster
    theme: [
      'tooltipster-borderless'
      'tooltipster-borderless-customized'
      'tooltipster-borderless-comment'
    ]
    debug: false
    maxWidth: 500

  $('.esc-tooltipped:disabled').tooltipster
    disable: true
    debug: false

  $(document).on 'click', (e)->
    if $('#webrep-advanced-search-button').size() > 0    
      if e.target.closest('.daterangepicker') == null && e.target.closest('.available') == null
        $("#advanced-search-dropdown").hide()
      else   # ensure webrep dash datepicker not open
        unless $('.ltr.show-calendar').css('display') == 'block'
          $("#advanced-search-dropdown").show()

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
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/user_preferences/"
    data: {name: 'WebRepEntriesPerPage'}
    success: (response) ->
      unless $('body').hasClass('escalations--file_rep--disputes-controller')
        response = JSON.parse(response)
        if response?
          $('select[name="disputes-index_length"]').val(response.entriesperpage)
          $('#disputes-index').DataTable().page.len(response.entriesperpage).draw('page')
          pageLength = response.entriesperpage
    )

  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/user_preferences/"
    data: {name: 'WebRepCurrentPage'}
    success: (response) ->
      response = JSON.parse(response)
      if response?
        $('#disputes-index').DataTable().page(response.currentpage).draw('page')
  )

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
      { data: 'last_email_date' }
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
      { data: 'last_email_date' }
      { data: 'total_email_count' }
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
      { data: 'last_email_date' }
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
      { data: 'last_email_date' }
      { data: 'total_email_count' }
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


  # Focus on the first field in the dropdown on open
  $('.dropdown').on 'shown.bs.dropdown', ->
    form = $(this).find('form')[0]
    if $(form).hasClass('add-host-ips')
      textarea = $(form).find('textarea')[0]
      $(textarea).focus()
    return


# Removes various new lines, extra spaces and crappy comma separation into single type of separation
window.cleanse_array = (array) ->
  clean_array = array.replace(/( +?)/g, '').replace(/( +?|\n+)/g, ',').split(',')


window.add_host_ips = (button) ->
  entry_id = $(button).attr('data-entry-id')
  form     = $(button).parents('.add-host-ips')[0]
  ips      = $(form).find('textarea').val()
  ip_array = []

  if ips.length > 0
    ip_array_initial = cleanse_array(ips)
    $(ip_array_initial).each ->
      ip = this.trim()
      ip_array.push(ip)

    # Refined ip array back to string for DOM
    final_ips = ip_array.join(', ')

    # Close the dropdown
    dropdown = $('#add_ip_button_' + entry_id).parent()
    $(dropdown).dropdown('toggle')

    # Create the IP rows
    parent_row = $(form).parents('.research-table-row')[0]
    uri_data_row = $(parent_row).find('.research-overview-row')[0]
    ip_row =
      '<tr class="research-uri-ip-query-row">' +
        '<td rowspan="2"></td>' +
        '<td class="input-col ip-label-col" rowspan="2"></td>' +
        '<td class="dual-edit-field" colspan="5" data-field="host-ip" data-id="' + entry_id + '">' +
          '<span class="entry-data entry-resolved-ip-content">' + final_ips + '</span>' +
          '<input class="table-ip-input wide" type="text" value="' + final_ips + '">' +
        '</td>' +
        '<td class="text-right no-padding-right" colspan="3">' +
          '<button class="edit-button inline-edit-ip-button esc-tooltipped" title="Edit IP Addresses">Edit IP Addresses</button>' +
          '<button class="save-button inline-save-ip-button esc-tooltipped" title="Save IP Addresses">Save IP Addresses</button>' +
          '<button class="cancel-button inline-cancel-ip-button esc-tooltipped"></button>' +
        '</td>' +
      '</tr>'

    ip_data_row =
      '<tr class="research-uri-ip-data-row">' +
        '<td class="research-table-details-wrapper" colspan="8">' +
          '<table><tbody>' +
            '<tr class="single-details-row">' +
              '<td><label>WBRS</label></td>' +
              '<td class="text-center no-border uri-ip-wbrs-score"></td>' +
              '<td><label>WBRS Rule Hits</label></td>' +
              '<td class="text-center uri-ip-wbrs-rule-total"></td>' +
              '<td><label>WBRS Rules</label></td>' +
              '<td class="uri-ip-wbrs-rules"></td>' +
              '<td><label>Threat Category</label></td>' +
              '<td class="uri-ip-category"></td>' +
              '<td><label>Proxy URI</label></td>' +
              '<td class="uri-ip-proxy"></td>' +
            '</tr>' +
          '</tbody></table>' +
        '</td>' +
      '</tr>'

    $(uri_data_row).after(ip_data_row)
    $(uri_data_row).after(ip_row)

    entry_uri = $($(parent_row).find('.entry-data-content')[0]).text()
    entry_uri = entry_uri.trim()

    # Time to make the donuts
    # Make call to sdsv3 to populate this beautiful new row
    query_uri_plus_ip(entry_uri, ip_array, parent_row)




window.query_uri_plus_ip = (uri, ips, entry_row) ->
  # Find our ip row for this entry in the DOM & insert inline loader
  ip_row = $(entry_row).find('.entry-resolved-ip-content')
  loader = '<span class="inline-row-loader"><span class="sync-button sync_rotate"></span>Loading...</span>'
  $(ip_row).after(loader)
  entry_id = $(entry_row).attr('data-entry-id')

  #  Could be called via the 'Add ips', the Save changes to an entry, or refresh data button
  #  Send the uri and ips to sdsv3
  std_msg_ajax(
    url: "/escalations/api/v1/escalations/webrep/disputes/update_multi_ip"
    method: 'POST'
    data: {
      uri: uri,
      ip_addresses: ips,
      dispute_entry_id: entry_id
    }
    success: (response) ->
      # Kill the loader and the 'Add IP Addresses' dropdown
      inserted_loader = $(entry_row).find('.inline-row-loader')
      $(inserted_loader).remove()
      dropdown = $('#add_ip_button_' + entry_id).parent()
      $(dropdown).remove()

      console.log response
      # Prep for inserting into DOM
      if response.json.rulehits?
        rules = []
        $(response.json.rulehits).each ->
          rules.push(this.mnemonic)
        rule_names = rules.join(', ')
        rule_hits = response.json.rulehits.length
      else
        rules = ''
        rule_hits = 0
      score     = response.json.score.toFixed(1)

      if response.json.threat_cats?
       threat_cats = response.json.threat_cats.join(', ')
      else
        threat_cats = ''

      if response.json.proxy_uri?
       proxy = response.json.proxy_uri
      else
        proxy = ''

      # Find our entry's (or result's) + ip data row and cells
      ip_data_row     = $(entry_row).find('.research-uri-ip-data-row')[0]
      wbrs_score_cell = $(ip_data_row).find('.uri-ip-wbrs-score')[0]
      wbrs_hits_cell  = $(ip_data_row).find('.uri-ip-wbrs-rule-total')[0]
      wbrs_rules_cell = $(ip_data_row).find('.uri-ip-wbrs-rules')[0]
      wbrs_cat_cell   = $(ip_data_row).find('.uri-ip-category')[0]
      wbrs_proxy_cell = $(ip_data_row).find('.uri-ip-proxy')[0]

      # Populate with our new data!
      $(wbrs_score_cell).text(score)
      $(wbrs_hits_cell).text(rule_hits)
      $(wbrs_rules_cell).text(rule_names)
      $(wbrs_cat_cell).text(threat_cats)
      $(wbrs_proxy_cell).text(proxy)

      # If there are rule hits, add to the rule hit details table
      wbrs_details_table = $($(entry_row).find('.wbrs-details-table')[0]).find('tbody')[0]
      plus_ip_rule_rows = $(wbrs_details_table).find('.plus-ip-rule-row')
      $(plus_ip_rule_rows).each ->
        $(this).remove()

      if rule_hits > 0
        $(response.json.rulehits).each ->
          probability = this.malware_probability / 100
          if probability > 50
            probability = '<span class="mal-highlight">' + probability + '%</span>'
          else
            probability = '<span>' + probability + '%</span>'

          rule_row = '<tr class="plus-ip-rule-row"><td class="uri-plus-ip-rule-indicator"></td><td>' + this.mnemonic + '</td><td>' + this.description + '</td><td class="text-center">' + probability + '</td></tr>'
          $(wbrs_details_table).append(rule_row)
      return
  )


$ ->
  # tooltip init these icons inside this DT, this MUST be on 'draw.dt', not page-load, DT doesn't exist on page-load
  $('#disputes-index').on 'draw.dt', ->
    $("#disputes-index .tooltipstered").tooltipster('destroy')  # remove existing dt tt attachments, then restore title attr
    $('#disputes-index .esc-tooltipped').tooltipster
      restoration: 'previous'
      theme: [
        'tooltipster-borderless'
        'tooltipster-borderless-customized'
      ]

  # subrow icons need the TT init on expand click, these icons don't exist on dt draw.dt
  $('#disputes-index .expand-row-button-inline').click ->
    $('.reputation-icon').tooltipster
      theme: [
        'tooltipster-borderless'
        'tooltipster-borderless-customized'
      ]


# Convert webrep to webcat
# Enable / disable button to attempt based on if anything is selected
$(document).on 'click', '#disputes-index tr, #disputes-index .dispute_check_box, #disputes_check_box', ->
  if $('input.dispute_check_box:checked').length == 1
    $('#convert-ticket-button').removeAttr('disabled')
  else
    $('#convert-ticket-button').attr('disabled', 'disabled')

# Prepare ticket for converting
window.prep_dispute_to_convert = (event) ->
  if $('tr.selected').length > 1
    # this shouldn't happen, but just in case
    std_msg_error('Too many rows selected', ['Please select only one row.'])
  else

    # get all data associated with the selected row
    dispute_row = $('tr.selected')[0]
    row_data = $('#disputes-index').DataTable().row(dispute_row).data()

    # conversion checks
    # - ti.com ticket
    # - open ticket

    if row_data.source == 'talos-intelligence' || row_data.source == 'talos-intelligence-api'
      ticket_status = $(row_data.status).text().trim();
      open_status = ['NEW', 'ASSIGNED', 'RESEARCHING', 'RE-OPENED', 'ESCALATED']
      if open_status.includes(ticket_status)
        dispute_id = row_data.id
        entries = row_data.dispute_entries
        summary = row_data.dispute_summary
        entry_count = entries.length

        $('#dispute-id-to-convert').text(dispute_id)
        $('.convert-entry-count').text('(' + entry_count + ')')
        $('#convert-ticket-summary').text(summary)

        # extra handling to deal with too many entries and overlapping issues with selectize
        if entry_count > 8
          $('.convert-entry-table-wrapper').addClass('max-scroll')
        else
          $('.convert-entry-table-wrapper').removeClass('max-scroll')

        entry_table = $('#entries-to-convert tbody')
        # clear out previous data
        $(entry_table).empty()

        # grab entry content for category lookup
        entries_content = []
        $(entries).each ->
          entry_content = ''
          if this.entry.entry_type == 'IP'
            entry_content = this.entry.ip_address
          else
            entry_content = this.entry.uri
          entries_content.push(entry_content)

        # get the current categories for the entries
        get_webrep_current_cats(entries, entries_content)
      else
        std_msg_error('Ticket cannot be converted', ['Selected ticket is not in a convertible (open) status.'])
        return
    else
      std_msg_error('Ticket cannot be converted', ['Selected ticket is not a customer ticket from talos-intelligence.'])
    return

window.prep_dispute_to_convert_from_research = (event) ->
  open_status = ['NEW', 'ASSIGNED', 'RESEARCHING', 'RE-OPENED', 'ESCALATED']
  ticket_status = $("#show-edit-ticket-status-button")[0].innerText
  ticket_source = $('#dispute-source-text')[0].innerText

  if !open_status.includes(ticket_status)
    std_msg_error('Ticket cannot be converted', ['Selected ticket is not in a convertible (open) status.'])
    return

  if ticket_source == 'TI Webform' || ticket_source == 'TI API'
    dispute_id = $("#dispute_id").text()
    entry_ids = []
    entries_content = []
    summary = $('.email-msg-content').text()

    for entry in $('.dual-edit-field.url-cell')
      entry_ids.push $(entry).attr('data-id')
      entries_content.push $(entry).find('.entry-data-content').text().replace(/^\s+|\s+$/g, '')

    $('#convert-ticket-summary').text(summary)
    $('#dispute-id-to-convert').text(dispute_id)
    $('.convert-entry-count').text("(#{entry_ids.length})")

    if $("#entries-to-convert tbody").find('tr').length > 0
      for row in $("#entries-to-convert tbody").find('tr')
        $(row).remove()

    get_webrep_current_cats_from_research(entry_ids, entries_content)

  else
    std_msg_error('Ticket cannot be converted', ['Selected ticket is not a customer ticket from talos-intelligence.'])
    return


$ ->

  # Check dropdown to decide when to enable the conversion submit button
  # check on dd click
  # check on selectize change
  # check on finish of population of entries (user may not need to alter anything)
  # - this will not work / be testable until the current cats come through
  $('#webrep-index-toolbar #convert-ticket-dropdown').click ->
    check_convert_to_webcat_ready()


check_convert_to_webcat_ready = () ->
  entry_cats = $('#webrep-index-toolbar #convert-ticket-dropdown').find('.selectize')
  enable = true
  # if any are not filled out we don't enable the submit button
  $(entry_cats).each ->
    if $(this).val() == null
      enable = false
  if enable == true
    $('#convert-ticket-dropdown .dropdown-submit-button').removeAttr('disabled')
  else
    $('#convert-ticket-dropdown .dropdown-submit-button').attr('disabled', 'disabled')
  return false

check_convert_to_webcat_ready_from_research = () ->
  entry_cats = $('#research-tab-toolbar #webrep-convert-ticket-dropdown').find('select.selectize')
  enable = true
  # if any are not filled out we don't enable the submit button
  $(entry_cats).each ->
    if $(this).val() == null
      enable = false
  if enable == true
    $('#convert-webrep-ticket-dropdown').removeAttr('disabled')
  else
    $('#convert-webrep-ticket-dropdown').attr('disabled', 'disabled')
  return false

get_webrep_current_cats = (entries, uris) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/current_content_categories'
    method: 'POST'
    headers: headers
    data: {
      uri: uris
    }
    success: (response) ->
      entry_table = $('#entries-to-convert tbody')
      $(entries).each ->
        entry = this
        entry_content = ''
        if this.entry.entry_type == 'IP'
          entry_content = this.entry.ip_address
        else
          entry_content = this.entry.uri

        cat_ids = []
        cat_names = ''
        $(response.data).each ->
          # find the response that corresponds to our entry
          if this[0].url == entry_content
            categories = this[0].categories
            # make this data usable
            cat_ids = []
            cat_names = []
            if Object.keys(categories).length > 0
              jQuery.each categories, (id, category) ->
                cat_ids.push(category.category_id)
                cat_names.push(category.descr)

            cat_names = cat_names.join()

        entry_row = '<tr><td class="align-top">' + this.entry.id + '</td><td class="entry-content-to-convert align-top">' + entry_content + '</td>' + '<td class="align-top">' + cat_names + '</td>' +
          '<td class="entry-cat-suggestions hidden" id="' + this.entry.id + '-selectize-holder"><select id="' + this.entry.id + '-selectize" class="selectize convert-entry-selectize" multiple="multiple" placeholder="Add categories"></select></td></tr>'

        $(entry_table).append(entry_row)
        entry_selectize_container = '#' + this.entry.id + '-selectize-holder'
        entry_select = '#' + this.entry.id + '-selectize'

        $convert_category_selectize = $(entry_select).selectize {
          persist: false,
          create: false,
          maxItems: 5,
          closeAfterSelect: true,
          valueField: 'category_id',
          labelField: 'category_name',
          searchField: ['category_name', 'category_code']
          options: AC.WebCat.createSelectOptions(entry_select)
          onChange: ->
            check_convert_to_webcat_ready()
        }


        setTimeout (->
          $(entry_selectize_container).removeClass('hidden')
          convert_selectize = $convert_category_selectize[0].selectize
          convert_selectize.setValue cat_ids

        ), 500


      check_convert_to_webcat_ready()
    error: (response) ->
      console.log response
      std_msg_error('Error preparing ticket for conversion', [response])
  )

get_webrep_current_cats_from_research = (entry_ids, uris) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/current_content_categories'
    method: 'POST'
    headers: headers
    data: {
      uri: uris
    }
    success: (response) ->
      entry_table = $('#entries-to-convert tbody')
      for entry_id, index in entry_ids
        entry_content = uris[index]
        cat_ids = []
        cat_names = ''

        for index, data of response.data
          if data.url == entry_content
            categories = data.categories
            cat_ids = []
            cat_names = []

            if Object.keys(categories).length > 0
              jQuery.each categories, (id, category) ->
                cat_ids.push category.category_id
                cat_names.push category.descr

            cat_names = cat_names.join()

        entry_row = "<tr><td class='align-top'>#{entry_id}</td><td class='entry-content-to-convert align-top'>#{entry_content}</td><td class='align-top'>#{cat_names}</td><td class='entry-cat-suggestions hidden' id='#{entry_id}-selectize-holder'><select id='#{entry_id}-selectize' class='selectize convert-entry-selectize' multiple='multiple' placeholder='Add categories'></select></td></tr>"

        $(entry_table).append(entry_row)
        entry_selectize_container = "##{entry_id}-selectize-holder"
        entry_select = "##{entry_id}-selectize"

        convert_category_selectize = $(entry_select).selectize {
          persist: false,
          create: false,
          maxItems: 5,
          closeAfterSelect: true,
          valueField: 'category_id',
          labelField: 'category_name',
          searchField: ['category_name', 'category_code']
          options: AC.WebCat.createSelectOptions(entry_select)
          onChange: ->
            check_convert_to_webcat_ready_from_research()
        }


        $(entry_selectize_container).removeClass('hidden')
        convert_selectize = convert_category_selectize[0].selectize
        convert_selectize.setValue cat_ids

      check_convert_to_webcat_ready_from_research()
    error: (response) ->
      console.error response
      std_msg_error("Error preparing ticket for conversion", [response])
  )

selected_options = (category_names) ->
  options = []
  if category_names
    options = category_names.split(',')
  return options

window.convert_dispute_to_webcat = () ->
  $('#convert-ticket-dropdown .dropdown-loader-wrapper').removeClass('hidden')
  dispute_id = $('#dispute-id-to-convert').text()
  summary = $('#convert-ticket-summary').val()

  # get the entries
  suggested_categories = []
  entry_rows = $('#entries-to-convert tbody tr')
  $(entry_rows).each ->
    entry_content = $(this).find('.entry-content-to-convert').text()
    suggested_cats_string = $(this).find('.convert-entry-selectize option:selected').map(->
      $(this).text()
    ).get().join(',')

    suggested_categories.push(entry: entry_content, suggested_categories: suggested_cats_string)

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/convert_ticket'
    method: 'POST'
    headers: headers
    data: {
      dispute_id: dispute_id
      summary: summary
      suggested_categories: suggested_categories
    }
    success: (response) ->
      console.log response
      $('#convert-ticket-dropdown .dropdown-loader-wrapper').addClass('hidden')
      std_msg_success('Success', ["Reputation Dispute converted to Categorization Complaint."], reload: true )
    error: (response) ->
      console.log response
      $('#convert-ticket-dropdown .dropdown-loader-wrapper').addClass('hidden')
      std_msg_error(response, ['Reputation Dispute unable to be converted to Categorization Complaint.'], reload: false)
  )

window.build_webrep_data = () ->
  $('#inline-webrep').removeClass('hidden')
  if location.search != ''
    urlParams = new URLSearchParams(location.search);
#      if the location.search has value, it is a standard search
    data =  {
      search_type : 'standard'
      search_name : urlParams.get('f')
    }

  else if localStorage.webRepFilters
    data = JSON.parse(localStorage.webRepFilters)

  format_webrep_header(data)

  data

window.format_webrep_header = (data) ->
  return if window.location.pathname != '/escalations/webrep/disputes'

  if data != undefined
    if data.search_name == 'unassigned'
      reset_icon = ''
    else
      reset_icon = '<span id="refresh-filter-button" class="reset-filter esc-tooltipped" title="Clear Search Results" onclick="reset_webrep_page()"></span>'

    { search_type, search_name } = data
    if search_type == 'standard'
      search_text =
        if search_name == 'my_disputes'
          'My Tickets'
        else if search_name == 'team_disputes'
          'My team Tickets'
        else
          search_name.replace(/_/g, ' ') + ' tickets'
      if search_name
        new_header =
          '<div>' +
          '<span class="text-capitalize">' + search_text + '</span>' +
          reset_icon +
          '</div>'
      else
        new_header = 'All Tickets'
    else if search_type == 'advanced'
      search_conditions = JSON.parse(localStorage.webRepFilters)
      new_header =
        '<div>Results for Advanced Search ' +
        reset_icon +
        '</div>'
      selectedFilters = []
      condition_types = {
        age_newer: 'Age more than'
        age_older: 'Age less than'
        case_id: 'Case IDs'
        case_owner_username: 'Assignee'
        modified_newer: 'Updated after'
        modified_older: 'Updated before'
        org_domain: 'Submitter domain'
        platform_names: 'Platform'
        priority: 'Priority'
        resolution: 'Resolution'
        status: 'Status'
        submitted_newer: 'Submitted after'
        submitted_older: 'Submitted before'
        submitter_type: 'Submitter Type'
        case_origin: 'Case Origin'
      }
      for conditionName, condition of search_conditions
        if condition == '' || ['search', 'search_name', 'search_type'].includes(conditionName)
          continue

        if conditionName == 'customer'
          for customer_type, customer_value of search_conditions[conditionName]
            if customer_value == ''
             continue
            if customer_type == 'name'
              selectedFilters.push({name: 'Contact Name', value: customer_value})
            if customer_type == 'email'
              selectedFilters.push({name: 'Contact Email', value: customer_value})
            if customer_type == 'company_name'
              selectedFilters.push({name: 'Submitter Org', value: customer_value})
        else if conditionName == 'dispute_entries'
          for key, value of search_conditions[conditionName]
            if value  == ''
             continue
            if key == 'ip_or_uri'
              selectedFilters.push({name: 'Dispute (URL/IP/Domain)', value: value})
            if key == 'suggested_disposition'
              selectedFilters.push({name: 'Suggested Disposition', value: value})
        else if conditionName == 'submission_type'
          selectedFilters.push({name: 'Submission Type', value: search_conditions[conditionName].map((e) => e.toUpperCase()).join(', ')})
        else if condition_types[conditionName]
          selectedFilters.push({name: condition_types[conditionName], value: search_conditions[conditionName]})
        container = $('#dispute-advaced-search-selected-filters')
      for item in selectedFilters
        html = '<span class="search-condition-name text-uppercase">' + item.name + ': </span>' + "<span class='search-condition'>" + item.value.split(',').join(', ') + '</span>'
        $('#dispute-advaced-search-selected-filters').append(html)
    else if search_type == 'named'
      new_header =
        '<div>Results for "' + search_name + '" Saved Search' +
        reset_icon +
        '</div>'
    else if search_type == 'contains' && data.value
      search_conditions = {value: 'typed_value' }
      new_header =
        '<div>Results for "' + data.value + '" '+
        reset_icon +
        '</div>'
    else
      new_header = 'All tickets'
    $('#dispute-index-title')[0].innerHTML = new_header

window.reset_webrep_page = () ->
  localStorage.removeItem('webRepFilters')
  refresh_webrep_url('?f=unassigned')
