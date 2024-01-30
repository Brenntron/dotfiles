## WEBCAT INDEX TOOLBAR FUNCTIONS ##


# Data display functions & storage

# Hide / Show data and columns on index table
$ ->
  $('.webcat-view-data-cb').click ->
    toggle_display_data(this)
    save_display_prefs()

window.get_display_prefs = () ->
  console.log 'getting display prefs'
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/user_preferences/"
    data: {name: 'WebCatVisible'}
    success: (response) ->
      response = JSON.parse(response)
      console.log response
      $.each response, (data, state) ->
        # HTML5 uses 'checked' rather than 'checked=true'
        checkbox = $("##{data}")
        if state == 'true'
          $(checkbox).prop('checked')
        else
          $(checkbox).removeAttr('checked')
        toggle_display_data(checkbox)
  )

toggle_display_data = (checkbox) ->
  # check if col or data toggle
  if $(checkbox).hasClass('webcat-view-col-cb')
    # this is a column toggle
    table = $('#complaints-index').DataTable()
    column = table.column($(checkbox).attr('data-column'))
    if $(checkbox).prop('checked')
      column.visible(true)
    else
      column.visible(false)
  else
    # this is a data toggle
    data_class = $(checkbox).attr('data-class')
    if $(checkbox).prop('checked')
      $('.' + data_class).show()
    else
      $('.' + data_class).hide()

save_display_prefs = () ->
  data = {}
  $('.webcat-view-data-cb').each ->
    data_id = $(this).attr('id')
    state = $(this).is(':checked')
    if state == true
      data[data_id] = 'true'
    else
      data[data_id] = 'false'

  std_msg_ajax(
    url: "/escalations/api/v1/escalations/user_preferences/update"
    method: 'POST'
    data: {data: data, name: 'WebCatVisible'}
    dataType: 'json'
    success: (response) ->
      console.log 'Webcat show/hide preferences are updated in user_prefs table.'
  )



# Sorting functions
window.sort_webcat_index = () ->
  order = $('#webcat-index-sort-order').attr('data-sort')
  sort_by = $('#webcat-index-sort-select').val()
  complaint_table = $('#complaints-index').DataTable()
  complaint_table
    .order( [ sort_by, order ] )
    .draw();

window.toggle_direct_sort = (col, field, button) ->
  order = $(button).attr('data-sort')
  if order == 'asc'
    $(button).attr('data-sort', 'desc')
    $(button).removeClass('sort-asc').addClass('sort-desc')
    title = 'Sort by ' + field + ': descending'
    $(button).attr('title', title)
  else
    $(button).attr('data-sort', 'asc')
    $(button).removeClass('sort-desc').addClass('sort-asc')
    title = 'Sort by ' + field + ': ascending'
    $(button).attr('title', title)

  complaint_table = $('#complaints-index').DataTable()
  complaint_table
    .order( [ col, order] )
    .draw();

window.toggle_select_order = (button) ->
  order = $(button).attr('data-sort')
  if order == 'asc'
    $(button).attr('data-sort', 'desc')
    $(button).removeClass('sort-asc').addClass('sort-desc')
    $(button).next().text('Descending')
  else
    $(button).attr('data-sort', 'asc')
    $(button).removeClass('sort-desc').addClass('sort-asc')
    $(button).next().text('Ascending')



# Selecting rows / enabling / disabling buttons based on selections
$ ->
  $('#complaints_select_all').click ->
    toggle_select_all_entries(this, '#complaints-index')
    check_enable_toolbar_buttons()

  $(document).on 'click', '#complaints-index tbody tr', ->
    check_enable_toolbar_buttons()

# Select all rows in datatable
window.toggle_select_all_entries = (checkbox, table) ->
  checked = $(checkbox).prop('checked')
  if checked
    $(table).DataTable().rows( { page: 'current' } ).select()
  else
    $(table).DataTable().rows().deselect()
  $(checkbox).prop('checked', checked)
  return

# Enable buttons if entries are selected
window.check_enable_toolbar_buttons = () ->
  if $('tr.selected').length >= 1
    $('.open-selected').removeAttr('disabled')
    $('#convert-ticket-button').removeAttr('disabled')
    $('.take-ticket-toolbar-button').removeAttr('disabled')
    $('.return-ticket-toolbar-button').removeAttr('disabled')
    $('.remove-assignee-toolbar-button').removeAttr('disabled')
    $('.ticket-owner-button').removeAttr('disabled')
  else
    $('.open-selected').attr('disabled', 'disabled')
    $('#convert-ticket-button').attr('disabled', 'disabled')
    $('.take-ticket-toolbar-button').attr('disabled', 'disabled')
    $('.return-ticket-toolbar-button').attr('disabled', 'disabled')
    $('.remove-assignee-toolbar-button').attr('disabled', 'disabled')
    $('.ticket-owner-button').attr('disabled', 'disabled')



# Opening urls in tabs

window.open_selected = () ->
  selected_rows = $('#complaints-index').DataTable().rows('.selected')
  if selected_rows[0].length == 0
    std_msg_error('No rows selected', ['Please select at least one row.'])
  else
    open_selected(selected_rows, "true")


window.open_all = () ->
  open_all = confirm("Are you sure you want to open ALL the windows on this page?!!")
  if (open_all == true)
    selected_rows = $('#complaints-index').DataTable().rows()
    open_selected(selected_rows, "true")


open_selected = (selected_rows, toggle) ->
  low_rep_entries = []
  error_message = ''

  for selected_row in selected_rows.data()
    { viewable, subdomain, domain, path, ip_address, wbrs_score } = selected_row
    if parseInt(wbrs_score) <= -6
      low_rep_entries.push selected_row
    else if viewable == toggle
      new_subdomain = ""
      new_domain = ""
      new_path = ""
      if path
        new_path = path
      if subdomain
        new_subdomain = subdomain + "."
      if domain
        new_domain = domain
        window.open("http://"+ new_subdomain + new_domain + new_path)
      else
        window.open("http://"+selected_row.ip_address)

  if low_rep_entries.length >= 10
    error_message = "#{low_rep_entries.length} row(s) could not open due to low WBRS Scores."
  else if low_rep_entries.length > 0
    domains_and_ips = []

    for lre in low_rep_entries
      if lre.domain
        domains_and_ips.push "<li>#{lre.domain}</li>"
      else
        domains_and_ips.push "<li>#{lre.ip_address}</li>"

    error_message = "#{low_rep_entries.length} row(s) could not open due to low WBRS Scores. <ul>#{domains_and_ips.join('')}</ul>"

  show_message('error', "#{error_message}", false, '#alertMessage')




# Assignment Functions #
# take unassigned as assignee
# take unassigned as reviewer
# take unassigned as second reviewer
# confirm below scenarios should be prevented - reviewer and second reviewer may not want to prevent
# unable to take assigned as assignee
# unable to take assigned as reviewer
# unable to take assigned as second reviewer
window.take_selected = ()->
  selected_rows = $('#complaints-index tr.selected')
  entry_ids = []
  $(selected_rows).each ->
    entry_id = $(this).attr('id')
    entry_ids.push(entry_id)
  assignment_type = $('.assignment-type-input:checked').val()
  if entry_ids.length > 0
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/take_entry'
      method: 'POST'
      headers: headers
      data: 'complaint_entry_ids': entry_ids, 'assignment_type': assignment_type
      success: (response) ->
        json = $.parseJSON(response)
        if json.error
          if jQuery.type(json.error) == 'array'
            std_msg_error('Error Taking Entries', [json.error.join(' ')])
          else
            std_msg_error('Error Taking Entries', [json.error])
        else
          # TODO add flash success
          $(selected_rows).each ->
            row = this
            if assignment_type == 'assignee'
              $(row).find('.assignee-row td').text(json.name)
              status = $(row).find('.state-row td')
              if ($(status).text() == 'NEW') || ($(status).text() == 'REOPENED')
                $(status).text('ASSIGNED')
            else if assignment_type == 'reviewer'
              $(row).find('.reviewer-row td').text(json.name)
            else if assignment_type == 'second_reviewer'
              $(row).find('.second-reviewer-row td').text(json.name)

      error: (response) ->
        std_msg_error('Error Taking Entries', response.responseText)
    , this)
  else
    std_msg_error('No rows selected', ['Please select at least one row.'])


window.return_selected = ()->
  selected_rows = $('#complaints-index tr.selected')
  entry_ids = []
  $(selected_rows).each ->
    entry_id = $(this).attr('id')
    entry_ids.push(entry_id)
  assignment_type = $('.assignment-type-input:checked').val()
  if entry_ids.length > 0
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/return_entry'
      method: 'POST'
      headers: headers
      data: 'complaint_entry_ids': entry_ids, 'assignment_type': assignment_type
      success: (response) ->
        json = $.parseJSON(response)
        if json.error
          if jQuery.type(json.error) != 'array'
            std_msg_error('Error Returning Entries', [json.error])
          else
            std_msg_error('Error Returning Entries', [json.error.join(' ')])
        else
          $(selected_rows).each ->
            row = this
            if assignment_type == 'assignee'
              $(row).find('.assignee-row td').text("Vrt Incoming")
              status = $(row).find('.state-row td')
              if $(status).text() == 'ASSIGNED'
                $(status).text('NEW')
            else if assignment_type == 'reviewer'
              $(row).find('.reviewer-row td').text("")
            else if assignment_type == 'second_reviewer'
              $(row).find('.second-reviewer-row td').text("")

      error: (response) ->
        std_msg_error('Error Returning Entries', [response.responseText])
    , this)
  else
    std_msg_error('no rows selected', ['Please select at least one row.'])



window.webcat_change_assignee = () ->
  selected_rows = $('#complaints-index tr.selected')
  entry_ids = []
  $(selected_rows).each ->
    entry_id = $(this).attr('id')
    entry_ids.push(entry_id)
  assignment_type = $('.assignment-type-input:checked').val()
  user_id = $('#index_target_assignee option:selected').val()

  if entry_ids.length > 0
    data = {
      'complaint_entry_ids': entry_ids,
      'user_id': user_id,
      'assignment_type': assignment_type
    }

    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/change_assignee'
      method: 'POST'
      headers: headers
      data: data
      dataType: 'json'
      success: (response) ->
        $('#webcat-change-assignee-index-dropdown').dropdown('toggle')
        json = $.parseJSON(response)
        if json.error
          if jQuery.type(json.error) != 'array'
            std_msg_error('Error Assigning Entries', [json.error])
          else
            std_msg_error('Error Assigning Entries', [json.error.join(' ')])
        else
          #TODO add flash success
          assignee = json.data[0].result.name
          $(selected_rows).each ->
            row = this
            if assignment_type == 'assignee'
              $(row).find('.assignee-row td').text(assignee)
              status = $(row).find('.state-row td')
              if ($(status).text() == 'NEW') || ($(status).text() == 'REOPENED')
                $(status).text('ASSIGNED')
            else if assignment_type == 'reviewer'
              $(row).find('.reviewer-row td').text(assignee)
            else if assignment_type == 'second_reviewer'
              $(row).find('.second-reviewer-row td').text(assignee)
      error: (response) ->
        std_msg_error('Error Assigning Entries', [response.responseText])
    )
  else
    std_msg_error('no rows selected', ['Please select at least one row.'])


window.webcat_remove_assignee = () ->
  selected_rows = $('#complaints-index tr.selected')
  entry_ids = []
  $(selected_rows).each ->
    entry_id = $(this).attr('id')
    entry_ids.push(entry_id)
  assignment_type = $('.assignment-type-input:checked').val()

  if entry_ids.length > 0
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/unassign_all'
      method: 'POST'
      headers: headers
      data: 'complaint_entry_ids': entry_ids, 'assignment_type': assignment_type
      success: (response) ->
        json = $.parseJSON(response)
        if json.error
          if jQuery.type(json.error) != 'array'
            std_msg_error('Error Removing Assignees', [json.error])
          else
            std_msg_error('Error Removing Assignees', [json.error.join(' ')])
        else
          $(selected_rows).each ->
            row = this
            if assignment_type == 'assignee'
              $(row).find('.assignee-row td').text("Vrt Incoming")
              status = $(row).find('.state-row td')
              if $(status).text() == 'ASSIGNED'
                $(status).text('NEW')
            else if assignment_type == 'reviewer'
              $(row).find('.reviewer-row td').text("")
            else if assignment_type == 'second_reviewer'
              $(row).find('.second-reviewer-row td').text("")

      error: (response) ->
        std_msg_error('Error Removing Assignees', [response.responseText])
    , this)
  else
    std_msg_error('no rows selected', ['Please select at least one row.'])



