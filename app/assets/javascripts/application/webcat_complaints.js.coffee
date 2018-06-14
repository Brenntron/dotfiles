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

window.check_preview_windows = () ->
  #visit site and check X-Frame-Options if same origin then you cant display it in the preview
  #snort.org for instance does this

window.display_preview_window = (id, subdomain, domain, path) ->
  #when checkbox is clicked take the domain and path and try to open it in the iframe
  if subdomain.length > 0
    subdomain = subdomain + "."
  loc = "http://" + subdomain + domain + path
  $("." + id + "_checkbox")[0].checked = true;
  document.getElementById('preview_window').src = loc
  document.getElementById('preview_window_header').innerHTML = loc

