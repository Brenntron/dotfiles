categories = [
  'Unknown',
  'Adult',
  'Advertisements',
  'Alcohol',
  'Arts',
  'Astrology',
  'Auctions',
  'Business and Industry',
  'Chat and Instant Messaging',
  'Cheating and Plagiarism',
  'Child Abuse Content',
  'Computer Security',
  'Computers and Internet'
  'DIY Projects',
  'Dating',
  'Digital Postcards',
  'Dining and Drinking',
  'Dynamic and Residential',
  'Education',
  'Entertainment',
  'Extreme',
  'Fashion',
  'File Transfer Services',
  'Filter Avoidance',
  'Finance',
  'Freeware and Shareware',
  'Gambling',
  'Games',
  'Government and Law',
  'Hacking',
  'Hate Speech',
  'Health and Nutrition',
  'Humor',
  'Hunting',
  'Illegal Activities',
  'Illegal Downloads',
  'Illegal Drugs',
  'Infrastructure',
  'Internet Telephony',
  'Job Search',
  'Lingerie and Swimsuits',
  'Lotteries',
  'Military',
  'Mobile Phones',
  'Nature',
  'News',
  'Non-governmental Organisations',
  'Non-sexual Nudity',
  'Online Communities',
  'Online Meetings',
  'Online Storage and Backup',
  'Online Trading',
  'Organisation Email',
  'Paranormal',
  'Parked Domains',
  'Peer File Transfer',
  'Personal Sites',
  'Personal VPN',
  'Photo Search and Images',
  'Politics',
  'Pornography',
  'Professional Networking',
  'Real Estate',
  'Reference',
  'Religion',
  'SaaS and B2B',
  'Safe for Kids',
  'Science and Technology',
  'Search Engines and Portals',
  'Sex Education',
  'Shopping',
  'Social Networking',
  'Social Science',
  'Society and Culture',
  'Software Updates',
  'Sports and Recreations',
  'Streaming Audio',
  'Streaming Video',
  'Tobacco',
  'Transportation',
  'Travel',
  'Weapons',
  'Web Hosting',
  'Web Page Translation',
  'Web-based Email',
  'This category is correct'
]

window.createSelectOptions = ->
  options = []
  for x in categories
    options.push {name: x}
  return options




window.removeSubdomain = (id,host) ->
  id.value = host

window.cat_new_url = ()->
  debugger

window.filterByStatus = (filter) ->
  populate_webcat_index_table(filter)

window.updatePending = (id,row_id) ->
  prefix = $('#complaint_review_prefix_'+id)[0].value
  status = $('[name=resolution_review_'+id+']:checked').val()
  comment = $('#complaint_pending_comment_'+id)[0].value
  resolution = $('.complaint-resolution'+id).text()
  category = $('.complaint-category'+id).text()
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
        temp_row.data().category = category
        temp_row.invalidate().draw()
        temp_row.data().is_important = false
        temp_row.child().remove()
        temp_row.child(format(temp_row)).show()
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
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        alert(json.error)
      else
        table = $('#complaints-index').DataTable()
        temp_row = table.row(row_id)
        temp_row.data().status = "PENDING"
        temp_row.data().category = categories
        temp_row.data().resolution = status
        temp_row.data().resolution_comment = comment
        temp_row.invalidate().draw()
        temp_row.data().is_important = true
        temp_row.child().remove()
        temp_row.child(format(temp_row)).show()
    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
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

  complaint_entry_html = ''
  if complaint_entry.is_important
    complaint_entry_html = '<div class="row">' +
      '<div class="col-xs-1">' +
      'ID <p>' + complaint_entry.entry_id + '</p>' +
      '</div>' +
      '<div class="col-xs-2">' +
      '<div class="row">' +
      '<div>Category:' +
      '<span class="complaint-category' + complaint_entry.entry_id + '">' + complaint_entry.category + '</span>' +
      '</div>'+
      '</div>' +
      '<div class="row">' +
      '<strong>' + url + '</strong>' +
      '</div>' +
      '<div class="row">' +
      '<div>Resolution: '+
      '<span class="complaint-resolution' + complaint_entry.entry_id + '">' + complaint_entry.resolution + '</span>' +
      '</div>'+
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
      '<input type="radio" name="resolution_review_' + complaint_entry.entry_id + '" value="commit" > commit | ' +
      '<input type="radio" name="resolution_review_' + complaint_entry.entry_id + '" value="decline" checked="checked"> decline' +
      '</div>' +
      '<div class="col-xs-1">' +
      '<button onclick="updatePending(' + complaint_entry.entry_id + ',' + row_id + ')"> Change </button>' +
      '</div>' +
      '<div class="col-xs-12">' + 'Comment: | <input id="complaint_pending_comment_' + complaint_entry.entry_id + '" type="text" onclick="this.select()" name="status" value="' + resolution_comment + '" placeholder="add a comment" size="50">' + '</div>' +
      '</div>'
  else
    input_cat = 'input_cat_' + complaint_entry.entry_id
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
      'Category: <select id="'+input_cat+'" name="['+input_cat+'][]" class="contacts selectized" placeholder="Enter up to 5 categories" multiple="multiple"></select>' +
      '</div>' +
      '<div class="col-xs-4">' +
      'Status: | ' +
      '<input type="radio" name="resolution' + complaint_entry.entry_id + '" value="unchanged" ' + unchanged_radio + entry_status + '> unchanged |  ' +
      '<input type="radio" name="resolution' + complaint_entry.entry_id + '" value="fixed"  ' + fixed_radio + entry_status + '> fixed | ' +
      '<input type="radio" name="resolution' + complaint_entry.entry_id + '" value="invalid" ' + invalid_radio + entry_status + '> invalid' +
      '</div>' +
      '<div class="col-xs-1">' +
      '<button onclick="updateEntryColumns(' + complaint_entry.entry_id + ',' + row_id + ')" ' + entry_status + '>Update</button>' +
      '</div>' +
      '</div>' +
      '</div>' +
      '<div class="col-xs-2">' +
      '<button>info</button>' +
      '<button>lookup</button>' +
      '<button>history</button>' +
      '<button>domain</button>' +
      '</div>' +
      '<div class="col-xs-12">' + 'Comment: | <input id="complaint_comment_' + complaint_entry.entry_id + '" type="text" onclick="this.select()" name="status" value="' + resolution_comment + '" placeholder="add a comment" size="50" ' + entry_status + '>' + '</div>' +
      '</div>'
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
    $(td).addClass 'complaint-entry-table-wrapper'
    $('#input_cat_'+ row.data().entry_id).selectize {
      persist: false,
      create: false,
      maxItems: 5
      valueField: 'name'
      labelField: 'name'
      searchField: 'name'
      options: createSelectOptions()

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

