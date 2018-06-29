window.populate_webcat_index_table = () ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webcat/complaints'
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

window.display_preview_window = (id, subdomain, domain, path) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  #when checkbox is clicked take the domain and path and try to open it in the iframe
  if subdomain.length > 0
    subdomain = subdomain + "."
  loc = "http://" + subdomain + domain + path
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
  $("#complaint_entry_row_"+ id ).addClass("complaint_selected")
  document.getElementById('preview_window').src = loc
  document.getElementById('preview_window_header_p').innerHTML = loc
  document.getElementById('preview_window_header_a').href = loc

window.select_all_pages = () ->
  $('[id$=_site_checkbox]').prop('checked', true);
window.unselect_all_pages = () ->
  $('[id$=_site_checkbox]').prop('checked', false);
window.open_viewable = () ->
  $('[id$=_site_checkbox]').each (site)->
    value = JSON.parse(this.value)
    if value.viewable == "true"
      window.open("http://www."+value.site)

window.open_nonviewable = () ->
  $('[id$=_site_checkbox]').each (site)->
    value = JSON.parse(this.value)
    if value.viewable == "false"
      window.open("http://www."+value.site)

window.open_selected = () ->
  $('[id$=_site_checkbox]:checked').each (site)->
    value = JSON.parse(this.value)
    window.open("http://www."+value.site)

window.open_all = () ->
  $('[id$=_site_checkbox]').each (site)->
    value = JSON.parse(this.value)
    window.open("http://www."+value.site)

window.mark_for_commit = () ->
  debugger
  entry_ids = $('#complaint-entries-div .complaint-entry-checkbox:checkbox:checked').map(() ->
    this.dataset['entryId']
  ).toArray()
  data = {
    'complaint_entry_ids': entry_ids
    'threat_category_list': $('#complaint_id_x_categories').val()
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
