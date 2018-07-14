window.removeSubdomain = (id,host) ->
  id.value = host

window.cat_new_url = ()->
  debugger

window.updateEntryColumns = (id) ->
  debugger

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

window.populate_webcat_index_table = () ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webcat/complaint_entries'
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

window.select_all_pages = () ->
  $('#complaints-index').DataTable().rows().select()
window.unselect_all_pages = () ->
  $('#complaints-index').DataTable().rows().deselect()
window.open_viewable = () ->
  selected_rows = $('#complaints-index').DataTable().rows()
  i = 0
  while i < selected_rows[0].length
    if selected_rows.data()[i].viewable == true
      window.open("http://www."+selected_rows.data()[i].domain)
    i++
window.open_nonviewable = () ->
  selected_rows = $('#complaints-index').DataTable().rows()
  i = 0
  while i < selected_rows[0].length
    if selected_rows.data()[i].viewable == false
      window.open("http://www."+selected_rows.data()[i].domain)
    i++
window.open_selected = () ->
  selected_rows = $('#complaints-index').DataTable().rows('.selected')
  i = 0
  while i < selected_rows[0].length
    window.open("http://www."+selected_rows.data()[i].domain)
    i++
window.open_all = () ->
  selected_rows = $('#complaints-index').DataTable().rows()
  i = 0
  while i < selected_rows[0].length
    window.open("http://www."+selected_rows.data()[i].domain)
    i++

    
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
