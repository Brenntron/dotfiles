## WEBCAT INDEX TOOLBAR FUNCTIONS ##

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

window.take_selected = ()->
  selected_rows = $('#complaints-index').DataTable().rows('.selected')
  if selected_rows[0].length > 0
    entry_ids = []
    for row, i in selected_rows[0]
      entry_ids.push(selected_rows.data()[i].entry_id)
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/take_entry'
      method: 'POST'
      headers: headers
      data: 'complaint_entry_ids': entry_ids
      success: (response) ->
        json = $.parseJSON(response)
        if json.error
          notice_html = "<p>Something went wrong: #{json.error}</p>"
          std_msg_error('Error Taking Entries', json.error)
        else
          for row, i in selected_rows[0]
            selected_rows.data().cell(selected_rows[0][i],14).data(json.name).draw()
            selected_rows.data().cell(selected_rows[0][i],4).data("ASSIGNED").draw()

      error: (response) ->
        notice_html = "<p>Something went wrong: #{response.responseText}</p>"
    , this)
  else
    std_msg_error('No rows selected', ['Please select at least one row.'])


window.return_selected = ()->
  selected_rows = $('#complaints-index').DataTable().rows('.selected')
  if selected_rows[0].length > 0
    entry_ids = []
    for row, i in selected_rows[0]
      entry_ids.push(selected_rows.data()[i].entry_id)
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/return_entry'
      method: 'POST'
      headers: headers
      data: 'complaint_entry_ids': entry_ids
      success: (response) ->
        json = $.parseJSON(response)
        if json.error
          notice_html = "<p>Something went wrong: #{json.error}</p>"
          std_msg_error('Error Returning Entries', json.error)
        else
          for row, i in selected_rows[0]
            selected_rows.data().cell(row,14).data("Vrt Incoming").draw()
            selected_rows.data().cell(row,4).data("NEW").draw()

      error: (response) ->
        notice_html = "<p>Something went wrong: #{response.responseText}</p>"
    , this)
  else
    std_msg_error('no rows selected', ['Please select at least one row.'])



window.webcat_change_assignee = () ->
  selected_rows = $('#complaints-index').DataTable().rows('.selected')
  if selected_rows[0].length > 0
    entry_ids = []
    for row, i in selected_rows[0]
      entry_ids.push(selected_rows.data()[i].entry_id)

    user_id = $('#index_target_assignee option:selected').val()

    data = {
      'complaint_entry_ids': entry_ids,
      'user_id': user_id
    }

    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/change_assignee'
      method: 'POST'
      headers: headers
      data: data
      dataType: 'json'
      success: (response) ->
        json = $.parseJSON(response)
        if json.error
          notice_html = "<p>Something went wrong: #{json.error}</p>"
          std_msg_error('Error Assigning Entries', json.error)
        else
#reload table data
          $('#complaints-index').DataTable().draw()

    )
  else
    std_msg_error('no rows selected', ['Please select at least one row.'])


window.webcat_remove_assignee = () ->
  selected_rows = $('#complaints-index').DataTable().rows('.selected')
  if selected_rows[0].length > 0
    entry_ids = []
    for row, i in selected_rows[0]
      entry_ids.push(selected_rows.data()[i].entry_id)
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/unassign_all'
      method: 'POST'
      headers: headers
      data: 'complaint_entry_ids': entry_ids
      success: (response) ->
        json = $.parseJSON(response)
        if json.error
          notice_html = "<p>Something went wrong: #{json.error}</p>"
          std_msg_error('Error Removing Assignees', json.error)
        else
          #reload table data
          $('#complaints-index').DataTable().draw()

      error: (response) ->
        notice_html = "<p>Something went wrong: #{response.responseText}</p>"
    , this)
  else
    std_msg_error('no rows selected', ['Please select at least one row.'])



