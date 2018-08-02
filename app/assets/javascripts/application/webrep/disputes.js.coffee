
window.populate_webrep_index_table = (data = {}) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep/disputes'
    method: 'GET'
    headers: headers
    data: data
    data_json: JSON.stringify(data)
    success: (response) ->
      $('#disputes-index-export-data-input').val(this.data_json)

      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        alert(json.error)
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
      #$("#alert_message").addClass('alert alert-danger alert-dismissable').append(notice_html)
      #$("#create_research_submit_wait").addClass('hidden').hide()
      #$("#create_research_submit").show()
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
    url: "/api/v1/escalations/webrep/disputes/searches/#{search_name}"
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
    url: '/api/v1/escalations/webrep/disputes/entry_wlbl'
    method: 'POST'
    data: data
    error_prefix: 'Error adjusting WL/BL.'
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
    url: '/api/v1/escalations/webrep/disputes/entry_wlbl'
    method: 'POST'
    data: data
    error_prefix: 'Error adjusting WL/BL.'
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
    url: '/api/v1/escalations/webrep/disputes/ticket_wlbl'
    method: 'POST'
    data: data
    error_prefix: 'Error adjusting WL/BL.'
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

window.toolbar_unassign_dispute = () ->
  single_id = $('#dispute_id').text()
  entry_ids = [single_id]

  data = {
    'dispute_ids': entry_ids
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep/disputes/unassign_all'
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


window.take_dispute = (take_button, dispute_id) ->
  std_msg_ajax(
    method: 'PATCH'
    url: "/api/v1/escalations/webrep/disputes/take_dispute/" + dispute_id
    data: {}
    td_tag: take_button.closest('td')
    dispute_id: dispute_id
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      this.td_tag.getElementsByClassName("dispute_username")[0].innerText = response.username
  )


window.take_disputes = () ->
  dispute_ids = $('.dispute_check_box:checkbox:checked').map(() ->
    this.dataset['entryId']
    this.value
  ).toArray()

  std_msg_ajax(
    method: 'PATCH'
    url: "/api/v1/escalations/webrep/disputes/take_disputes"
    data: { dispute_ids: dispute_ids }
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      for dispute_id in response.dispute_ids
        $('#owner_' + dispute_id).text(response.username)
  )


window.save_dispute_entries = () ->
  data = {}
  $('#disputes-research-table').find('tr.research-table-row').each(() ->
    result = {}
    fielddata = $(this).find('.dual-edit-field').map(() ->
      new_value = switch (this.dataset.field)
        when 'status' then $(this).find('.table-entry-input')[0].innerText.trim()
        else $(this).find('.table-entry-input')[0].value.trim()

      {
        id: this.dataset.id
        field: this.dataset.field
        old: $(this).find('.entry-data')[0].innerText.trim()
        new: new_value
      }
    ).toArray().filter((field_data) ->
      field_data.old != field_data.new
    )
    if 0 < fielddata.length
      data[this.dataset.entryId] = fielddata
  )
  std_msg_ajax(
    method: 'PATCH'
    url: "/api/v1/escalations/webrep/disputes/entries/field_data"
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
    url: '/api/v1/escalations/webrep/disputes/' + form_tag.dataset.disputeId + '/related_disputes'
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
    url: '/api/v1/escalations/webrep/disputes/' + related_dispute_id + '/relating_disputes'
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
    url: '/api/v1/escalations/webrep/disputes/' + form_tag.dataset.disputeId + '/duplicate_disputes'
    data: { duplicate_dispute_id: duplicate_dispute_id }
    success_reload: true
    error_prefix: 'Error marking duplicate relationship.'
  )



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
        targets: [6]
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
          '<span class="bug-priority p-P' + data + '"></span>'

      }
      { data: 'case_link' }
      { data: 'status' }
      { data: 'resolution' }
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
      { data: 'source_id' }
      {
        data: null
        defaultContent: ''
      }
      { data: 'submitter_name' }
      { data: 'submitter_org' }
      { data: 'submitter_domain' }
      {
        data: null
        defaultContent: ''
      }
    ])

  format = (dispute) ->
    table_head = '<table class="table dispute-entry-table">' + '<thead>' + '<tr>' + '<th><input type="checkbox"></th>' + '<th class="entry-col-content">Dispute Entry</th>' + '<th class="entry-col-status">Dispute Entry Status</th>' + '<th class="entry-col-disp">Suggested Disposition</th>' + '<th class="entry-col-cat">Category</th>' + '<th class="entry-col-wbrs-score">WBRS Score</th>' + '<th class="entry-col-wbrs-hits">WBRS Total Rule Hits</th>' + '<th class="entry-col-wbrs-rules">WBRS Rules</th>' + '<th class="entry-col-sbrs-score">SBRS Score</th>' + '<th class="entry-col-sbrs-hits">SBRS Total Rule Hits</th>' + '<th class="entry-col-sbrs-rules">SBRS Rules</th>' + '<th class="entry-col-wlbl">WL/BL Entries</th>' + '<th class="entry-col-reptool-class">RepTool Classification</th>' + '</tr>' + '</thead>' + '<tbody>'
    entry = dispute.dispute_entries
    missing_data = '<span class="missing-data">Missing Data</span>'
    entry_rows = []
    $(entry).each ->
      entry_content = ''
      if @ip_address != null
        entry_content = @ip_address
      else if @uri != null
        entry_content = @uri
      else
        entry_content = missing_data
      category = ''
      if @primary_category != null
        category = @primary_category
      else
        category = missing_data
      status = ''
      if @status != null
        status = @status
      else
        status = missing_data
      suggested_disposition = ''
      if @suggested_disposition != null
        suggested_disposition = @suggested_disposition
      else
        suggested_disposition = missing_data
      if @is_important == true
        important = 'entry-important-flag'
      else
        important = ''
      entry_row = '<tr>' + '<td><input type="checkbox" class="dispute-entry-checkbox"></td>' + '<td class="entry-col-content ' + important + '">' + entry_content + '</td>' + '<td class="entry-col-status">' + status + '</td>' + '<td class="entry-col-disp">' + suggested_disposition + '</td>' + '<td class="entry-col-cat">' + category + '</td>' + '<td class="entry-col-wbrs-score">' + @score + '</td>' + '<td class="entry-col-wbrs-hits"></td>' + '<td class="entry-col-wbrs-rules"></td>' + '<td class="entry-col-sbrs-score"></td>' + '<td class="entry-col-sbrs-hits"></td>' + '<td class="entry-col-sbrs-rules"></td>' + '<td class="entry-col-wlbl"></td>' + '<td class="entry-col-reptool-class"></td>' + '</tr>'
      entry_rows.push entry_row
      return
    # `d` is the original data object for the row
    table_head + entry_rows.join('') + '</tbody></table>'

  populate_webrep_index_table()

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
