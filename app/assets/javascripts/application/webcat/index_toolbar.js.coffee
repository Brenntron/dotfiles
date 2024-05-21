## WEBCAT INDEX TOOLBAR FUNCTIONS ##


# Data display functions & storage

# Hide / Show data and columns on index table
$ ->
  $('.webcat-view-data-cb').click ->
    toggle_display_data(this)
    save_display_prefs()

  $("#self_review").click ->
    self_review = $(this).prop('checked')

    data = {"enabled": self_review}
    std_msg_ajax(
      url: "/escalations/api/v1/escalations/user_preferences/update"
      method: "POST"
      data: {data, name: "SelfReview"}
      dataType: "json"
      success: (response) ->
    )

window.get_display_prefs = () ->
  current_filter = get_current_webcat_filter() #check which page user is on for filter purposes
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/user_preferences/"
    data: {name: current_filter}
    success: (response) ->
      response = JSON.parse(response)
      #check for userpref, if null get default filter values
      if response == null
        response = get_default_webcat_filter_data(current_filter)
      $.each response, (data, state) ->
        # HTML5 uses 'checked' rather than 'checked=true'
        checkbox = $("##{data}")
        if state == 'true'
          $(checkbox).prop('checked')
        else
          $(checkbox).removeAttr('checked')
        toggle_display_data(checkbox)
  )

get_current_webcat_filter = ->
  filter = localStorage.getItem 'webcat_search_name'
  if filter == '?f=NEW TALOS'
    return 'WebcatNewTalosColumns'
  else if filter == '?f=NEW WBNP'
    return 'WebcatNewWbnpColumns'
  else if filter == '?f=NEW JIRA'
    return 'WebcatNewJiraColumns'
  else if filter == '?f=NEW INTERNAL'
    return 'WebcatNewInternalColumns'
  else
    return 'WebcatDefaultColumns'

#load default filter values from the bottom of this page
get_default_webcat_filter_data = (current_filter) ->
  switch (current_filter)
    when 'WebcatDefaultColumns'
      return webcat_default_column_filter
    when 'WebcatNewTalosColumns'
      return webcat_new_talos_tickets_column_filter
    when 'WebcatNewWbnpColumns'
      return webcat_new_wbnp_tickets_column_filter
    when 'WebcatNewJiraColumns'
      return webcat_new_jira_tickets_column_filter
    when 'WebcatNewInternalColumns'
      return webcat_new_internal_tickets_column_filter

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

  current_filter = get_current_webcat_filter()

  std_msg_ajax(
    url: "/escalations/api/v1/escalations/user_preferences/update"
    method: 'POST'
    data: {data: data, name: current_filter}
    dataType: 'json'
    success: (response) ->
      console.log 'Webcat show/hide preferences are updated in user_prefs table.'
  )


# Sorting functions
window.sort_webcat_index = () ->
  # clear any previously set direct sort residue
  window.unset_active_sort()

  # set dropdown sort vals
  dir = $('#webcat-index-sort-order').attr('data-sort')
  col = $('#webcat-index-sort-select').val()

  $('#webcat-index-table-sort-button').addClass('active-sort')
  if dir == 'asc'
    full_dir = 'ascending'
  else
    full_dir = 'descending'
  field = $('#webcat-index-sort-select option[value=' + col + ']').text()
  $('#webcat-index-table-sort-button').tooltipster('content', 'Sorted by ' + field + ' : ' + full_dir );

  if $($('#webcat-index-table-sort-button').parent('.dropdown')[0]).hasClass('open')
    $('#webcat-index-table-sort-button').dropdown('toggle')

  # disable all sort buttons temporarily while the data loads
  $('#webcat-index-table-sort-button').attr('disabled', true)
  $('#sort-btn-group button').attr('disabled', true)
  $('#complaints-index').DataTable().order(col, dir).draw();
  $('#complaints-index').DataTable().on 'draw', ->
    get_display_prefs()


window.toggle_direct_sort = (col, field, button) ->
  current_order = $(button).attr('data-sort')
  window.unset_active_sort()
  if $(button).hasClass('active-sort')
    # if button is currently active, then toggle to opposite direction on click
    # otherwise the displayed order on the button is the desired order to change to
    if current_order == 'asc'
      desired_order = 'desc'
    else
      desired_order = 'asc'
  else
    # employ currently visible sort & set to active
    # clear current active direct sort
    $('#sort-btn-group .active-sort').removeClass('active-sort')
    $(button).addClass('active-sort')
    desired_order = current_order

  if desired_order == 'asc'
    $(button).attr('data-sort', 'asc')
    $(button).removeClass('sort-desc').addClass('sort-asc')
    title = 'Sorted by ' + field + ': ascending | Click to reverse.'
  else
    $(button).attr('data-sort', 'desc')
    $(button).removeClass('sort-asc').addClass('sort-desc')
    title = 'Sorted by ' + field + ': descending | Click to reverse.'

  $(button).tooltipster('content', title);

  # disable all sort buttons temporarily while the data loads
  $('#webcat-index-table-sort-button').attr('disabled', true)
  $('#sort-btn-group button').attr('disabled', true)
  $('#complaints-index').DataTable().order(col, desired_order).draw();
  $('#complaints-index').DataTable().on 'draw', ->
    get_display_prefs()


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


window.set_active_sort = () ->
  # clear any existing active sort settings
  window.unset_active_sort()

  curr_sort = $('#complaints-index').DataTable().order()
  col = curr_sort[0].toString()
  direction = curr_sort[1]

  # Somewhere 'dec' is getting sent instead of 'desc' - remove this line if we find the culprit
  if direction == 'dec'
    direction = 'desc'

  if direction == 'desc'
    full_dir = 'descending'
  else
    full_dir = 'ascending'

  if col == '10' || col == '12'
    # check if active direct sort button matches
    $('#sort-btn-group button').each ->
      field = $(this).text()
      curr_dir = $(this).attr('data-sort')

      if col == $(this).attr('data-column')
        $(this).addClass('active-sort')
        $(this).tooltipster('content', 'Sorted by ' + field + ': ' + full_dir + ' | Click to reverse.' );
        if direction != $(this).attr('data-sort')
          $(this).removeClass('sort-asc').removeClass('sort-desc').addClass('sort-' + direction)
          $(this).attr('data-sort', direction)
      else
        $(this).removeClass('active-sort')
        if curr_dir == 'desc'
          full_dir = 'descending'
        else
          full_dir = 'ascending'
        $(this).tooltipster('content', 'Sort by ' + field + ': ' + full_dir);

    $('#webcat-index-table-sort-button').tooltipster('content', 'Sort by Data');

  else
    # sort is being implemented via the sort dropdown
    # set active-sort on button, load selected option, direction arrow, and label in dropdown
    if direction == 'asc'
      label = 'Ascending'
    else
      label = 'Descending'
    $('#webcat-index-table-sort-button').addClass('active-sort')
    $('#webcat-index-sort-select').val(col)
    $('#webcat-index-sort-order').removeClass('sort-asc').removeClass('sort-desc').addClass('sort-' + direction)
    $('#webcat-index-sort-order').attr('data-sort', direction)
    $('#webcat-index-sort-order').next('label').text(label)
    field = $('#webcat-index-sort-select option[value=' + col + ']').text()
    $('#webcat-index-table-sort-button').tooltipster('content', 'Sorted by ' + field + ': ' + full_dir );


window.unset_active_sort = () ->
  $('#sort-btn-group .active-sort').removeClass('active-sort')
  # restore tooltips to non-active values
  $('#sort-btn-group button').each ->
    button_dir = $(this).attr('data-sort')
    button_field = $(this).text()
    if button_dir == 'asc'
      button_dir = 'ascending'
    else
      button_dir = 'descending'
    $(this).tooltipster('content', 'Sort by ' + button_field + ': ' + button_dir);

  # clear active settings from dropdown sort
  $('#webcat-index-table-sort-button').removeClass('active-sort')
  $('#webcat-index-table-sort-button').tooltipster('content', 'Sort by Data');


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
    if $('.ticket-owner-button').attr('data-user-role') == 'manager'
      $('.ticket-owner-button').removeAttr('disabled')

  else
    $('.open-selected').attr('disabled', 'disabled')
    $('#convert-ticket-button').attr('disabled', 'disabled')
    $('.take-ticket-toolbar-button').attr('disabled', 'disabled')
    $('.return-ticket-toolbar-button').attr('disabled', 'disabled')
    $('.remove-assignee-toolbar-button').attr('disabled', 'disabled')
    $('.ticket-owner-button').attr('disabled', 'disabled')



# Opening urls in tabs

window.open_selected_urls = () ->
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
        ipv4_regex = /^(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)){3}$/gm

        # Because IPv6 includes colons an IPv6 must be wrapped in square brackets if it's used as a hostname.
        if ipv4_regex.test(selected_row.ip_address)
          window.open("http://#{selected_row.ip_address}")
        else
          console.log "Opening #{selected_row.ip_address}"
          window.open("http://[#{selected_row.ip_address}]")

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
        $('#index_change_assign').dropdown('toggle')
        json = $.parseJSON(response)
        if json.error
          if jQuery.type(json.error) != 'array'
            std_msg_error('Error Assigning Entries', [json.error])
          else
            std_msg_error('Error Assigning Entries', [json.error.join(' ')])
        else
          #TODO add flash success
          assignee = json.name
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



## Webcat Default Filters ##
## Load these when no userpref data found for that filter ##
## Default is used for all except New Talos Tickets, New WBNP Tickets, New Jira Tickets and New Internal Tickets
webcat_default_column_filter = {
  "view-ticket-col-cb": "true",
  "view-data-entry-id": "false",
  "view-data-age": "true",
  "view-data-status": "true",
  "view-data-source": "false",
  "view-submitter-col-cb": "true",
  "view-data-org-cb": "true",
  "view-data-name-cb": "true",
  "view-data-email-cb": "false",
  "view-data-platform-cb": "true",
  "view-user-col-cb": "false",
  "view-data-assignee-cb": "false",
  "view-data-reviewer-cb": "false",
  "view-data-sec-reviewer-cb": "false",
  "view-tags-col-cb": "true",
  "view-description-col-cb": "true",
  "view-sugg-col-cb": "true",
  "view-tools-col-cb": "false"
}
webcat_new_talos_tickets_column_filter = {
  "view-ticket-col-cb": "true",
  "view-data-entry-id": "false",
  "view-data-age": "true",
  "view-data-status": "true",
  "view-data-source": "false",
  "view-submitter-col-cb": "true",
  "view-data-org-cb": "true",
  "view-data-name-cb": "false",
  "view-data-email-cb": "false",
  "view-data-platform-cb": "true",
  "view-user-col-cb": "false",
  "view-data-assignee-cb": "false",
  "view-data-reviewer-cb": "false",
  "view-data-sec-reviewer-cb": "false",
  "view-tags-col-cb": "false",
  "view-description-col-cb": "true",
  "view-sugg-col-cb": "true",
  "view-tools-col-cb": "false"
}
webcat_new_wbnp_tickets_column_filter = {
  "view-ticket-col-cb": "true",
  "view-data-entry-id": "false",
  "view-data-age": "true",
  "view-data-status": "true",
  "view-data-source": "false",
  "view-submitter-col-cb": "false",
  "view-data-org-cb": "false",
  "view-data-name-cb": "true",
  "view-data-email-cb": "false",
  "view-data-platform-cb": "false",
  "view-user-col-cb": "false",
  "view-data-assignee-cb": "false",
  "view-data-reviewer-cb": "false",
  "view-data-sec-reviewer-cb": "false",
  "view-tags-col-cb": "false",
  "view-description-col-cb": "false",
  "view-sugg-col-cb": "false",
  "view-tools-col-cb": "false"
}
webcat_new_jira_tickets_column_filter = {
  "view-ticket-col-cb": "true",
  "view-data-entry-id": "false",
  "view-data-age": "true",
  "view-data-status": "true",
  "view-data-source": "false",
  "view-submitter-col-cb": "false",
  "view-data-org-cb": "false",
  "view-data-name-cb": "false",
  "view-data-email-cb": "false",
  "view-data-platform-cb": "true",
  "view-user-col-cb": "false",
  "view-data-assignee-cb": "false",
  "view-data-reviewer-cb": "false",
  "view-data-sec-reviewer-cb": "false",
  "view-tags-col-cb": "true",
  "view-description-col-cb": "true",
  "view-sugg-col-cb": "false",
  "view-tools-col-cb": "false"
}
webcat_new_internal_tickets_column_filter = {
  "view-ticket-col-cb": "true",
  "view-data-entry-id": "false",
  "view-data-age": "true",
  "view-data-status": "true",
  "view-data-source": "false",
  "view-submitter-col-cb": "false",
  "view-data-org-cb": "false",
  "view-data-name-cb": "false",
  "view-data-email-cb": "false",
  "view-data-platform-cb": "true",
  "view-user-col-cb": "false",
  "view-data-assignee-cb": "false",
  "view-data-reviewer-cb": "false",
  "view-data-sec-reviewer-cb": "false",
  "view-tags-col-cb": "true",
  "view-description-col-cb": "false",
  "view-sugg-col-cb": "false",
  "view-tools-col-cb": "false"
}