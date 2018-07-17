window.removeSubdomain = (id,host) ->
  id.value = host

window.cat_new_url = ()->
  debugger

window.filterByStatus = (filter) ->
  populate_webcat_index_table(filter)

window.updatePending = (id) ->
  prefix = $('#complaint_review_prefix_'+id)[0].value
  status = $('[name=resolution_review_'+id+']:checked').val()
  comment = $('#complaint_pending_comment_'+id)[0].value
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webcat/complaint_entries/update_pending'
    method: 'POST'
    headers: headers
    data: {'id': id,'prefix': prefix,'commit':status,'comment':comment }
    success: (response) ->
      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        alert(json.error)
      else
        debugger

    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)

window.updateEntryColumns = (id) ->
  prefix = $('#complaint_prefix_'+id)[0].value
  categories = $('#complaint_categories_'+id)[0].value
  status = $('[name=resolution'+id+']:checked').val()
  comment = $('#complaint_comment_'+id)[0].value
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

  $.ajax(
    url: '/api/v1/escalations/webcat/complaint_entries/update'
    method: 'POST'
    headers: headers
    data: {'id': id,'prefix': prefix,'categories':categories,'status':status,'comment':comment }
    success: (response) ->
      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        alert(json.error)
      else
        debugger

    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)


window.take_selected = ()->
  selected_rows = $('#complaints-index').DataTable().rows('.selected')
  entry_ids = []
  i = 0
  while i < selected_rows[0].length
    entry_ids.push(selected_rows.data()[i].entry_id)
    i++
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webcat/complaint_entries/take_entry'
    method: 'POST'
    headers: headers
    data: 'complaint_entry_ids': entry_ids
    success: (response) ->
      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        alert(json.error)
      else
        i = 0
        while i < selected_rows[0].length
          selected_rows.data().cell(selected_rows[0][i],12).data(json.name).draw()
          selected_rows.data().cell(selected_rows[0][i],5).data("ASSIGNED").draw()
          i++

    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)



window.return_selected = ()->
  selected_rows = $('#complaints-index').DataTable().rows('.selected')
  entry_ids = []
  i = 0
  while i < selected_rows[0].length
    entry_ids.push(selected_rows.data()[i].entry_id)
    i++
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webcat/complaint_entries/return_entry'
    method: 'POST'
    headers: headers
    data: 'complaint_entry_ids': entry_ids
    success: (response) ->
      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        alert(json.error)
      else
        i = 0
        while i < selected_rows[0].length
          selected_rows.data().cell(selected_rows[0][i],12).data("").draw()
          selected_rows.data().cell(selected_rows[0][i],5).data("NEW").draw()
          i++

    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)

window.select_cat_text_field = (id) ->
  if (typeof numericalValue)
    $( "#category_input"+id ).select();

window.edit_selected_complaints = () ->
  selected_rows = $('#complaints-index').DataTable().rows('.selected')
  complaint_ids = []
  i = 0
  while i < selected_rows[0].length
    complaint_ids.push(selected_rows.data()[i].complaint_id)
    i++
  window.location = 'show_multiple?selected_ids=' + complaint_ids;



format = (complaint_entry) ->
  missing_data = '<span class="missing-data">Missing Data</span>'
  uri = ''
  host = ''
  url = ''
  if complaint_entry.uri
    uri = '<a href="http://' + complaint_entry.uri + '" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + complaint_entry.uri + '</a>'
  else if complaint_entry.domain
    if complaint_entry.subdomain
      host = complaint_entry.subdomain + '.'
    host = host + complaint_entry.domain
    url = host
    if complaint_entry.path
      url = host + complaint_entry.path
    uri = '<a href="http://' + url + '" target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + url + '</a>'
  else
    uri = missing_data

  entry_status = ""
  if complaint_entry.status == "COMPLETED"
    entry_status = "disabled='true'"
  wbrs_score = ''
  if complaint_entry.wbrs_score
    wbrs_score = complaint_entry.wbrs_score
  else
    wbrs_score = missing_data
  confidence = ''
  if complaint_entry.confidence
    confidence = complaint_entry.confidence
  else
    confidence = missing_data
  certainty = ''
  if complaint_entry.certainty
    certainty = complaint_entry.certainty
  else
    certainty = missing_data
  category = ''
  if complaint_entry.category
    category = complaint_entry.category
  else
    category = ''
  complaint_entry_html = ''
  if complaint_entry.is_important
    complaint_entry_html = '<div class="row">' +
      '<div class="col-xs-1">' +
      'ID <p>' + complaint_entry.entry_id + '</p>' +
      '</div>' +
      '<div class="col-xs-2">' +
      '<div class="row">' +
      'Category:' + complaint_entry.category +
      '</div>' +
      '<div class="row">' +
      '<h3>' + url + '</h3>' +
      '</div>' +
      '</div>' +
      ' <div class="col-xs-3">' +
      'Prefix <input id="complaint_review_prefix_' + complaint_entry.entry_id + '" type="text" onclick="this.select()" value="' + host + '"><button onclick="removeSubdomain(complaint_review_prefix_' + complaint_entry.entry_id + ',\'' + complaint_entry.domain + '\')">remove subdomain</button>' +
      '</div>' +
      '<div class="col-xs-1">' +
      '<div class="row">' + 'Certainty: <p>' + certainty + '</p>' +
      '</div>' +
      '<div class="row">' + 'Confidence: <p>' + confidence + '</p>' +
      '</div>' +
      '</div>' +
      '<div class="col-xs-4">' +
      ' Resolution: | ' +
      '<input type="radio" name="resolution_review_' + complaint_entry.entry_id + '" value="commit" checked="checked"> commit | ' +
      '<input type="radio" name="resolution_review_' + complaint_entry.entry_id + '" value="decline"> decline' +
      '</div>' +
      '<div class="col-xs-1">' +
      '<button onclick="updatePending(' + complaint_entry.entry_id + ')"> Change </button>' +
      '</div>' +
      '<div class="col-xs-12">' + 'Comment: | <input id="complaint_pending_comment_' + complaint_entry.entry_id + '" type="text" onclick="this.select()" name="status" value="" placeholder="add a comment" size="50">' + '</div>' +
      '</div>'
  else
    complaint_entry_html = '<div class="row">' +
      '<div class="col-xs-10">' +
      '<div class="row">' +
      '<div class="col-xs-1">' + complaint_entry.complaint_id + '/' + complaint_entry.entry_id + ' </div>' +
      '<div class="col-xs-3">' + uri +
      '</div>' +
      '<div class="col-xs-4">' +
      'Prefix <input id="complaint_prefix_' + complaint_entry.entry_id +
      '" type="text" onclick="this.select()" value="' + host +
      '"' + entry_status + '>' +
      '<button onclick="removeSubdomain(complaint_prefix_' + complaint_entry.entry_id +
      ',\'' + complaint_entry.domain + '\')"' + entry_status + '>remove subdomain</button>' +
      '</div>' +
      '<div class="col-xs-2">' +
      'WBRS: ' + wbrs_score + ' Confidence ' + confidence +
      '</div>' +
      '</div>' +
      '<div class="row">' +
      '<div class="col-xs-4">' +
      'Category<input id="complaint_categories_' + complaint_entry.entry_id +
      '" type="text" onclick="this.select()" value="' + category + '"' + entry_status + '>' +
      '</div>' +
      '<div class="col-xs-4">' +
      'Status: | ' +
      '<input type="radio" name="resolution' + complaint_entry.entry_id + '" value="unchanged" ' + entry_status + '> unchanged |  ' +
      '<input type="radio" name="resolution' + complaint_entry.entry_id + '" value="fixed" checked="checked" ' + entry_status + '> fixed | ' +
      '<input type="radio" name="resolution' + complaint_entry.entry_id + '" value="invalid" ' + entry_status + '> invalid' +
      '</div>' +
      '<div class="col-xs-1">' +
      '<button onclick="updateEntryColumns(' + complaint_entry.entry_id + ')" ' + entry_status + '>Update</button>' +
      '</div>' +
      '</div>' +
      '</div>' +
      '<div class="col-xs-2">' +
      '<button>info</button>' +
      '<button>lookup</button>' +
      '<button>history</button>' +
      '<button>domain</button>' +
      '</div>' +
      '<div class="col-xs-12">' + 'Comment: | <input id="complaint_comment_' + complaint_entry.entry_id + '" type="text" onclick="this.select()" name="status" value="" placeholder="add a comment" size="50" ' + entry_status + '>' + '</div>' +
      '</div>'
  complaint_entry_html

window.click_table_buttons = (complaint_table, button)->
  tr = $(button).closest('tr')
  row = complaint_table.row(tr)
  if row.child.isShown()       # This row is already open - close it
    row.child.hide()
    tr.removeClass 'shown'
    tr.addClass 'not-shown'
  else                         # Open this row
    row.child(format(row.data())).show()
    tr.removeClass 'not-shown'
    tr.addClass 'shown'
    td = $(tr).next('tr').find('td:first')
    $(td).addClass 'complaint-entry-table-wrapper'
    # Check to see which columns should be displayed
    $('.toggle-vis-nested').each ->
      checkbox_trigger = $(button).attr('data-column')
      checkbox = $(this).find('input')
      if $(checkbox).prop('checked')
        $('.complaint-entry-table td, .complaint-entry-table th').each ->
          if $(button).hasClass(checkbox_trigger)
            $(button).show()
      else if $(checkbox).prop('checked') == false
        $('.complaint-entry-table td, .complaint-entry-table th').each ->
          if $(button).hasClass(checkbox_trigger)
            $(button).hide()

window.populate_webcat_index_table = (filter) ->
  self_review = $('#self_review')[0].checked
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webcat/complaint_entries?filter_by='+filter+'&self_review='+self_review
    method: 'GET'
    headers: headers
    success: (response) ->

      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        alert(json.error)
      else
        datatable = $('#complaints-index').DataTable()
        datatable.clear();
        datatable.rows.add(json.data);
        datatable.draw();

    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
      #$("#alert_message").addClass('alert alert-danger alert-dismissable').append(notice_html)
      #$("#create_research_submit_wait").addClass('hidden').hide()
      #$("#create_research_submit").show()
  , this)

window.display_preview_window = (entry) ->

  $('#complaint_id_x_prefix')[0].value = entry.domain
  $('#complaint_id_x_categories')[0].value = entry.category
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  #when checkbox is clicked take the domain and path and try to open it in the iframe
  path = ""
  subdomain = ""
  if entry.subdomain
    subdomain = entry.subdomain + "."
  if entry.path
    path = entry.path
  loc = "http://" + subdomain + entry.domain + path
  $.ajax(
    url: '/api/v1/escalations/webcat/complaints/test_url'
    method: 'GET'
    headers: headers
    data: {
      url:loc
    }
    success: (response) ->
      #yay you can visit the site
    error: (response) ->
      #that page wont load. lets display someting else
      switch response["status"]
        when 404
          document.getElementById('preview_window').src = "/unknown_url.html"
        when 403
          document.getElementById('preview_window').src = "/same_origin_url.html"

  , this)

  $(".complaint_selected" ).removeClass("complaint_selected")
  $("#complaint_entry_row_"+ entry.id ).addClass("complaint_selected")
  document.getElementById('preview_window').src = loc
  document.getElementById('preview_window_header_p').innerHTML = loc
  document.getElementById('preview_window_header_a').href = loc

open_selected = (selected_rows, toggle) ->
  i = 0
  while i < selected_rows[0].length
    if selected_rows.data()[i].viewable == toggle
      window.open("http://www."+selected_rows.data()[i].domain)
    i++

window.select_all_pages = () ->
  $('#complaints-index').DataTable().rows().select()
window.unselect_all_pages = () ->
  $('#complaints-index').DataTable().rows().deselect()
window.open_viewable = () ->
  selected_rows = $('#complaints-index').DataTable().rows()
  open_selected(selected_rows, true)
window.open_nonviewable = () ->
  selected_rows = $('#complaints-index').DataTable().rows()
  open_selected(selected_rows, false)
window.open_selected = () ->
  selected_rows = $('#complaints-index').DataTable().rows('.selected')
  open_selected(selected_rows, true)
window.open_all = () ->
  selected_rows = $('#complaints-index').DataTable().rows()
  open_selected(selected_rows, true)


toggle_selected = (table, selected_rows)->
  i = 0
  while i < selected_rows[0].length
    button = $( ".expand-row-button-inline" )[selected_rows[0][i]]
    click_table_buttons(table, button)
    i++

window.collapse_selected =()->
  table = $('#complaints-index').DataTable()
  selected_rows = table.rows('.shown.selected')
  toggle_selected(table,selected_rows)
window.collapse_all =()->
  table = $('#complaints-index').DataTable()
  selected_rows = table.rows('.shown')
  toggle_selected(table,selected_rows)

window.expand_selected =()->
  table = $('#complaints-index').DataTable()
  selected_rows = table.rows('.selected.not-shown')
  toggle_selected(table,selected_rows)
window.expand_all =()->
  table = $('#complaints-index').DataTable()
  selected_rows = table.rows('.not-shown')
  toggle_selected(table,selected_rows)


window.mark_for_commit = () ->
  entry_ids = $('#complaint-entries-div .complaint-entry-checkbox:checkbox:checked').map(() ->
    this.dataset['entryId']
  ).toArray()
  data = {
    'complaint_entry_ids': entry_ids
    'category_list': $('#complaint_id_x_categories').val()
    'comment': $('#complaint_id_x_comment').val()
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webcat/complaints/mark_for_commit'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    error: (response) ->
      popup_response_error(response, 'Error marking for commit')
  )

window.commit_marked = () ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webcat/complaints/commit_marked'
    method: 'POST'
    headers: headers
    data: {}
    dataType: 'json'
    error: (response) ->
      popup_response_error(response, 'Error committing marked entries.')
  )
