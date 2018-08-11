window.removeSubdomain = (id,host) ->
  id.value = host

window.cat_new_url = ()->
  data = {}
  for i in [1...6] by 1
    data[i] = {url: $("#url_#{i}").val(), cats: $("#cat_new_url_#{i}").val()}
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

  $.ajax(
    url:'/api/v1/escalations/webcat/complaints/cat_new_url'
    method: 'POST'
    headers: headers
    data: {data: data}
    success: (response) ->
      std_msg_success('URLs categorized successfully.',"", reload: true)
    error: (response) ->
      std_msg_error(response,"", reload: false)
  )

window.filterByStatus = (filter) ->
  populate_webcat_index_table(filter)

window.updatePending = (id,row_id) ->
  prefix = $('#complaint_review_prefix_'+id)[0].value
  status = $('[name=resolution_review_'+id+']:checked').val()
  comment = $('#complaint_pending_comment_'+id)[0].value
  resolution = $('.complaint-resolution'+id).text()

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
        table = $('#complaints-index').DataTable()
        temp_row = table.row(row_id)

        temp_row.data().status = json.status
        temp_row.data().resolution = resolution
        temp_row.data().resolution_comment = comment
        temp_row.invalidate().draw()
        temp_row.child().remove()
        temp_row.child(format(temp_row)).show()
        $('#input_cat_'+ temp_row.data().entry_id).selectize {
          persist: false,
          create: false,
          maxItems: 5,
          valueField: 'value',
          labelField: 'value',
          searchField: ['text'],
          options: AC.WebCat.createSelectOptions(),
          items: selected_options(temp_row.data().category)
        }
    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)

window.updateEntryColumns = (entry_id,row_id) ->
  prefix = $('#complaint_prefix_'+entry_id)[0].value
  categories = $('#input_cat_'+entry_id).val().toString()
  status = $('[name=resolution'+entry_id+']:checked').val()
  comment = $('#complaint_comment_'+entry_id)[0].value
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

  $.ajax(
    url: '/api/v1/escalations/webcat/complaint_entries/update'
    method: 'POST'
    headers: headers
    data: {'id': entry_id,'prefix': prefix,'categories':categories,'status':status,'comment':comment }
    success: (response) ->
      json = $.parseJSON(response)
      if json.error
        std_msg_error(response,"", reload: false)
      else
        table = $('#complaints-index').DataTable()
        temp_row = table.row(row_id)
        temp_row.data().status = json.status
        temp_row.data().resolution = status
        temp_row.data().resolution_comment = comment
        temp_row.data().category = categories
        temp_row.invalidate().draw()
        temp_row.child().remove()
        temp_row.child(format(temp_row)).show()
        $('#input_cat_'+ temp_row.data().entry_id).selectize {
          persist: false,
          create: false,
          maxItems: 5
          valueField: 'value'
          labelField: 'value'
          searchField: 'text'
          options: AC.WebCat.createSelectOptions()
          items: selected_options(temp_row.data().category)
        }
    error: (response) ->
      std_msg_error(response,"", reload: false)
  , this)


window.take_selected = ()->
  selected_rows = $('#complaints-index').DataTable().rows('.selected')
  if selected_rows[0].length > 0
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
  if selected_rows[0].length > 0
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
            selected_rows.data().cell(selected_rows[0][i],12).data("Vrt Incoming").draw()
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
  if selected_rows.count() > 0
    complaint_ids = []
    i = 0
    while i < selected_rows[0].length
      complaint_ids.push(selected_rows.data()[i].complaint_id)
      i++
    window.location = 'show_multiple?selected_ids=' + complaint_ids;
  else
    std_msg_error("alert",["There was an error. Please select an entry to edit"])

selected_options = (categories) ->
  options = []
  if categories
    options = categories.split(',')
  return options

format = (complaint_entry_row) ->
  complaint_entry = complaint_entry_row.data()
  row_id = complaint_entry_row[0][0]
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
  else if  complaint_entry.ip_address
    host = complaint_entry.ip_address
    url = host
    uri = '<a href="http://' + complaint_entry.ip_address + '" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + complaint_entry.ip_address + '</a>'
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
  resolution_comment=''
  if complaint_entry.resolution_comment
    resolution_comment = complaint_entry.resolution_comment
  disposition = ''
  if complaint_entry.suggested_disposition
    disposition = complaint_entry.suggested_disposition
  else
    disposition = missing_data
  unchanged_radio = ""
  fixed_radio = ""
  invalid_radio = ""
  if complaint_entry.resolution
    switch (complaint_entry.resolution)
      when "unchanged"
        unchanged_radio = "checked='checked'"
      when "fixed"
        fixed_radio = "checked='checked'"
      when "invalid"
        invalid_radio = "checked='checked'"
  else
    fixed_radio = "checked='checked'"

  complaint_entry_html = ''
  if complaint_entry.status == "PENDING"
    complaint_entry_html = '<table><tr>' +
      '<td>' + url + '<br/>' +
      'Prefix <input id="complaint_review_prefix_' + complaint_entry.entry_id + '" type="text" onclick="this.select()" value="' + host + '"><button onclick="removeSubdomain(complaint_review_prefix_' + complaint_entry.entry_id + ',\'' + complaint_entry.domain + '\')">remove subdomain</button>' +
      '<td>Status:<br/>' + '<span class="complaint-resolution' + complaint_entry.entry_id + '">' + complaint_entry.resolution + '</span>' +
      '<td>Certainty:' + certainty + '<br/>Confidence:' + confidence + '</td>' +
      '<td>Suggested Disposition<br/>' + disposition + '</td>' +
      '<td>Category: <span class="complaint-category' + complaint_entry.entry_id + '">' + complaint_entry.category + '</span></td>' +

      '<td>Resolution:<br/>' +
      '<input type="radio" name="resolution_review_' + complaint_entry.entry_id + '" value="commit" > Commit <br/>' +
      '<input type="radio" name="resolution_review_' + complaint_entry.entry_id + '" value="decline" checked="checked"> Decline' +
      '<td><button onclick="updatePending(' + complaint_entry.entry_id + ',' + row_id + ')"> Change </button>' + '</td>' +
      '</tr><tr>' +
      '<td>' + 'Comment: | <input id="complaint_pending_comment_' + complaint_entry.entry_id + '" type="text" onclick="this.select()" name="status" value="' + resolution_comment + '" placeholder="add a comment" size="50">' + '</td>'
  else
    input_cat = 'input_cat_' + complaint_entry.entry_id
    complaint_entry_html = '<table><tr>' +
      '<td>' + uri + '<br/>' +
      'Prefix <input class="nested-table-input" id="complaint_prefix_' + complaint_entry.entry_id +
      '" type="text" onclick="this.select()" value="' + host +
      '"' + entry_status + '>' +
      '<button onclick="removeSubdomain(complaint_prefix_' + complaint_entry.entry_id +
      ',\'' + complaint_entry.domain + '\')"' + entry_status + '>remove subdomain</button></td>' +
      '<td>Status<br/>' +
      '<input type="radio" id="unchanged' + complaint_entry.entry_id + '" name="resolution' + complaint_entry.entry_id + '" value="UNCHANGED" ' + unchanged_radio + entry_status + '> Unchanged <br/> ' +
      '<input type="radio" id="fixed' + complaint_entry.entry_id + '" name="resolution' + complaint_entry.entry_id + '" value="FIXED"  ' + fixed_radio + entry_status + '> Fixed  <br/> ' +
      '<input type="radio" id="invalid' + complaint_entry.entry_id + '" name="resolution' + complaint_entry.entry_id + '" value="INVALID" ' + invalid_radio + entry_status + '> Invalid' +
      '</td>' +
      '<td>Confidence<br/>' + confidence + '</td>' +
      '<td>Suggested Disposition<br/>' + disposition + '</td>' +
      '<td>' +
      '<button>info</button>' +
      '<button>lookup</button>' +
      '<button>history</button>' +
      '<button>domain</button>' +
      '</td></tr>' +
      '<tr>' +
      '<td>Category: <fieldset id="'+input_cat+'" ' + entry_status + '  name="['+input_cat+'][]" class="contacts selectize" placeholder="Enter up to 5 categories" value="">' +
      '<td colspan="3">' +
      'Comment: | <input id="complaint_comment_' + complaint_entry.entry_id + '" type="text" onclick="this.select()" name="status" value="' + resolution_comment + '" placeholder="add a comment" size="50" ' + entry_status + '>'  +
      '</td>' +
      '<td><button onclick="updateEntryColumns(' + complaint_entry.entry_id + ',' + row_id + ')" ' + entry_status + '>Update</button>' +
      '</td></tr></table>'
  complaint_entry_html


window.click_table_buttons = (complaint_table, button)->
  tr = $(button).closest('tr')
  row = complaint_table.row(tr)
  if row.child.isShown()       # This row is already open - close it
    row.child.hide()
    tr.removeClass 'shown'
    tr.addClass 'not-shown'
  else
    # Open this row
    row.child(format(row)).show()
    tr.removeClass 'not-shown'
    tr.addClass 'shown'
    td = $(tr).next('tr').find('td:first')
    unless $(td).hasClass 'nested-complaint-data-wrapper'
      $(td).addClass 'nested-complaint-data-wrapper'
    $('#input_cat_'+ row.data().entry_id).selectize {
      persist: false,
      create: false,
      maxItems: 5,
      valueField: 'value',
      labelField: 'value',
      searchField: ['text'],
      options: AC.WebCat.createSelectOptions()
      items: selected_options(row.data().category)
    }
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
  if $('body.index-action').length
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
      subdomain = ""
      domain = ""
      path = ""
      if selected_rows.data()[i].subdomain
        subdomain = selected_rows.data()[i].subdomain + "."
      if selected_rows.data()[i].domain
        domain = selected_rows.data()[i].domain
      if selected_rows.data()[i].path
        path = selected_rows.data()[i].path
      if selected_rows.data()[i].domain
        window.open("http://"+ subdomain + domain + path)
      else
        window.open("http://"+selected_rows.data()[i].ip_address)
    i++

$ ->
  $('#complaints_check_box').click ->
    if $('#complaints_check_box').prop('checked')
      $('#complaints-index').DataTable().rows().select()
    else
      $('#complaints-index').DataTable().rows().deselect()
  return

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


window.advanced_webcat_index_table = () ->
  data = {
    customer: {
      name: $('#cat_named_search').find('input[id="name-input"]').val()
      email: $('#cat_named_search').find('input[id="email-input"]').val()
      company_name: $('#cat_named_search').find('input[id="company-input"]').val()
    }
    complaint_entries: {
      ip_or_uri: $('#cat_named_search').find('input[id="complaint-input"]').val()
      resolution: $('#cat_named_search').find('select[id="resolution-input"]').val()
      category: $('#cat_named_search').find('input[id="category-input"]').val()
      status: $('#cat_named_search').find('select[id="status-input"]').val()
      complaint_id: $('#cat_named_search').find('input[id="complaintid-input"]').val()
    }
    search_type: 'advanced'
    search_name: $('#cat_named_search').find('input[name="search_name"]').val()
    description: $('#cat_named_search').find('input[id="desc-input"]').val()
    channel: $('#cat_named_search').find('select[id="channel-input"]').val()
    tags: $('#cat_named_search').find('select[id="tags-input"]').val() || []
    submitted_older: $('#cat_named_search').find('input[id="submitted-older-input"]').val()
    submitted_newer: $('#cat_named_search').find('input[id="submitted-newer-input"]').val()
    modified_older: $('#cat_named_search').find('input[id="modified-older-input"]').val()
    modified_newer: $('#cat_named_search').find('input[id="modified-newer-input"]').val()
  }
  window.populate_advanced_webcat_index_table(data)


window.populate_advanced_webcat_index_table = (data = {}) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webcat/complaint_entries'
    method: 'GET'
    headers: headers
    data: data
    data_json: JSON.stringify(data)
    success: (response) ->
      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        alert(json.error)
      else
        $('.tickets-totals-table').trigger("click") #close open dropdowns
        datatable = $('#complaints-index').DataTable()
        datatable.clear();
        datatable.rows.add(json.data);
        datatable.draw();

      error: (response) ->
        std_api_error(response, "There was an error loading search results.", reload: false)
  , this)


window.named_webcat_index_table = (search_name) ->
  data = {
    search_type: 'named'
    search_name: search_name
  }
  window.populate_advanced_webcat_index_table(data)


$ ->
  $(document).ready ->
    if window.location.pathname != '/escalations/webcat/complaints'
      $('#filter-complaints').hide()
      $('#fetch').hide()
      $('#web-cat-search').hide()
      $('#new-complaint').hide()
    else
      $('#filter-complaints').show()
      $('#fetch').show()
      $('#web-cat-search').show()
      $('#new-complaint').show()

