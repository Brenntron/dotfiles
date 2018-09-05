window.removeSubdomain = (id,host) ->
  id.value = host

window.cat_new_url = ()->
  event.preventDefault()
  $('#loader-modal').modal({
    backdrop: 'static',
    keyboard: false
  })
  data = {}
  for i in [1...6] by 1
    data[i] = {url: $("#url_#{i}").val(), cats: $("#cat_new_url_#{i}").val()}
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

  $.ajax(
    url:'/escalations/api/v1/escalations/webcat/complaints/cat_new_url'
    method: 'POST'
    headers: headers
    data: {data: data}
    success: (response) ->
      $('#loader-modal').hide()
      std_msg_success('URLs categorized successfully.',["Categorization of a Top URL will create a pending complaint entry.", "All other entries have been submitted directly to WBRS."], reload: true)
    error: (response) ->
      $('#loader-modal').hide()
      $('.modal-backdrop').remove();
      std_msg_error(response,"", reload: false)
  )

window.multiple_url_categorization = ()->
  event.preventDefault()
  $('#loader-modal').modal({
    backdrop: 'static',
    keyboard: false
  })
  data = {}
  for i in [1...6] by 1
    data[i] = {url: $("#multi_url_#{i}").val(), cats: $("#multi_cat_url_cats").val()}
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

  $.ajax(
    url:'/escalations/api/v1/escalations/webcat/complaints/cat_new_url'
    method: 'POST'
    headers: headers
    data: {data: data}
    success: (response) ->
      $('#loader-modal').hide()
      std_msg_success('URLs categorized successfully.',"", reload: true)
    error: (response) ->
      $('#loader-modal').hide()
      $('.modal-backdrop').remove();
      std_msg_error('Error:' + ' ' + response.responseJSON.message,"", reload: false)
  )

name_servers =(server_list)->
  i = 0
  text = ""
  while i < server_list.length
    text += server_list[i] + '<br>'
    i++
  text

format_domain_info = (info)->
  '<div class="dialog-content-wrapper">' +
    '<h5>Domain Name</h5>' +
    '<p>' + info.domain_name + '</p>' +
    '<hr class="thin">' +
    '<h5>Registrant </h5>' +
    '<table class="nested-dialog-table">' +
      '<tr>' +
        '<td class="table-side-header">' +
           'Organization' +
        '</td>' +
        '<td>' +
          info.registrant_organization +
      '</tr><tr>' +
        '<td class="table-side-header">' +
          'Country' +
        '</td>' +
        '<td>' +
          info.registrant_country +
        '</td>' +
      '</tr><tr>' +
        '<td class="table-side-header">' +
        'State/Province' +
        '</td>' +
        '<td>' +
          info['registrant_state/province'] +
        '</td>' +
      '</tr>' +
    '</table>' +
    '<hr class="thin">' +
    '<h5>Name Servers</h5>'+
    name_servers(info.name_server) +
    '<hr class="thin">' +
    '<h5> Dates</h5>'+
    '<table class="nested-dialog-table">' +
      '<tr>' +
        '<td class="table-side-header">' +
          'Created' +
        '</td>' +
        '<td>' + info.creation_date + '</td>'+
      '</tr><tr>' +
        '<td class="table-side-header">' +
          'Last updated' +
        '</td>' +
        '<td>' +
          info.updated_date +
        '</td>' +
      '</tr><tr>' +
        '<td class="table-side-header">' +
          'Expiry_date' +
        '</td>' +
        '<td>' +
          info.registry_expiry_date +
        '</td>' +
      '</tr>' +
    '</table>' +
  '</div>'

window.domain_whois = (IP_Domain) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/domain_whois'
    method: 'POST'
    headers: headers
    data: {'lookup': IP_Domain}
    success: (response) ->
      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        alert(json.error)
      else
        dialog_content = $(format_domain_info(json))
        if $("#complaint_button_dialog").length
          complaint_dialog = this

          $('#complaint_button_dialog').html("")
          $('body').innerHTML=""

          $('body').append(complaint_dialog)
          $('#complaint_button_dialog').append(dialog_content[0])
          $('#complaint_button_dialog').dialog
            autoOpen: true
            minWidth: 400
            position: { my: "right bottom", at: "right bottom", of: window }
        else
          complaint_dialog = '<div id="complaint_button_dialog" title="Domain Information"></div>'
          $('body').append(complaint_dialog)
          $('#complaint_button_dialog').append(dialog_content[0])
          $('#complaint_button_dialog').dialog
            autoOpen: true
            minWidth: 400
            position: { my: "right bottom", at: "right bottom", of: window }
    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)

window.filterByStatus = (filter) ->
  populate_webcat_index_table(filter)

window.updatePending = (id,row_id) ->
  prefix = $('#complaint_prefix_'+id)[0].value
  status = $('[name=resolution_review_'+id+']:checked').val()
  comment = $('#complaint_comment_'+id)[0].value
  resolution_comment = $('#complaint_resolution_comment_'+id)[0].value
  resolution = $('.complaint-resolution'+id).text()
  categories = $('#input_cat_'+id).val().toString()

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/update_pending'
    method: 'POST'
    headers: headers
    data: {'id': id,'prefix': prefix,'commit':status,'status':resolution,'comment':comment, 'resolution_comment': resolution_comment, 'categories': categories }
    success: (response) ->
      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        alert(json.error)
      else
        table = $('#complaints-index').DataTable()
        temp_row = table.row(row_id)

        if json.was_dismissed
          temp_row.node().className += ' highlight-was-dismissed'

        temp_row.data().status = json.status
        temp_row.data().resolution = resolution
        temp_row.data().internal_comment = comment
        temp_row.data().resolution_comment = resolution_comment
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
  $("#submit_changes_#{entry_id}").prop("disabled",true)
  prefix = $('#complaint_prefix_'+entry_id)[0].value
  categories = $('#input_cat_'+entry_id).val().toString()
  status = $('[name=resolution'+entry_id+']:checked').val()
  comment = $('#complaint_comment_'+entry_id)[0].value
  resolution_comment = $('#complaint_resolution_comment_'+entry_id)[0].value
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/update'
    method: 'POST'
    headers: headers
    data: {'id': entry_id,'prefix': prefix,'categories':categories,'status':status,'comment':comment, 'resolution_comment': resolution_comment }
    success: (response) ->
      json = $.parseJSON(response)
      if json.error
        if categories.length == 0
          std_msg_error("Must include at least one category.","", reload: false)
        else
          std_msg_error(response,"", reload: false)
      else
        table = $('#complaints-index').DataTable()
        temp_row = table.row(row_id)
        temp_row.data().status = json.status
        temp_row.data().resolution = status
        temp_row.data().internal_comment = comment
        temp_row.data().resolution_comment = resolution_comment
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
        $('#input_cat_pending'+ temp_row.data().entry_id).selectize {
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
      $("#submit_changes_#{entry_id}").prop("disabled",false)
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
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/take_entry'
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
            selected_rows.data().cell(selected_rows[0][i],14).data(json.name).draw()
            selected_rows.data().cell(selected_rows[0][i],4).data("ASSIGNED").draw()
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
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/return_entry'
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

$('html').on 'click', (e) ->
  if typeof $(e.target).data('original-title') == 'undefined' and !$(e.target).parents().is('.popover.in')
    $('[data-original-title]').popover 'hide'

window.enlarge_image = (id,image)->
  $('#screenshot_id_'+ id).popover(
    html: true
    container: 'body'
    trigger: 'focus'
    content: '<img src="' + image + '">').popover 'show'

window.lookup_prefix = () ->

  event.preventDefault()

  $('#loader-modal').show()
  $('.modal-backdrop').show()

  $('#loader-modal').modal({
    backdrop: 'static',
    keyboard: false
  })

  urls = []

  for i in [1 .. 5]
    $select= $('#cat_new_url_' + i).selectize()
    selectize = $select[0].selectize
    selectize.clear()
    urls.push($("#url_" + i ).val())

  std_msg_ajax(
    url:'/escalations/api/v1/escalations/webcat/complaints/lookup_prefix'
    method: 'POST'
    data: { 'urls': urls }

    success: (response) ->
      i = 1
      for [i .. 5]
        j = 0
        try
          for [j .. response.json[i].data.length]
            selector = '#cat_new_url_' + i.toString()
            $select= $(selector).selectize()
            selectize = $select[0].selectize
            selectize.addItem(response.json[i].data[j].descr)
            j++
        catch
          i++
          continue
        i++
      $('#loader-modal').hide()
      $('.modal-backdrop').hide()
  )

window.retrieve_history = (position) ->

  url = $("#url_" + position).val()

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/categorize_urls_history'
    method: 'POST'
    data: {'position': position, url: url}
    success: (response) ->
      json = JSON.parse(response)

      if json.error
        std_msg_error("<p>Something went wrong: #{json.error}","")
      else
        #parse this json properly
        history_dialog_content = '<div class="dialog-content-wrapper">' +
          '<h5>Domain History</h5>' +
          '<table class="history-table"><thead><tr><th>Action</th><th>Confidence</th><th>Description</th><th>Time</th><th>User</th><th>Category</th></tr></thead>' +
          '<tbody>'

        for entry in json

          entry_string = "" +
            '<tr>' +
            '<td>' + entry['action'] + '</td>' +
            '<td>' + entry['confidence'] + '</td>' +
            '<td>' + entry['description'] + '</td>' +
            '<td>' + entry['time'] + '</td>' +
            '<td>' + entry['user'] + '</td>' +
            '<td>' + entry['category']['descr'] + '</td>' +
            '</tr>'

          history_dialog_content += entry_string
        history_dialog_content += '</tbody></table>'
        history_dialog_content += '<hr class="thin"/>'

        if $("#history_dialog").length
          history_dialog = this
          $("#history_dialog").html(history_dialog_content)
          $('#history_dialog').dialog('open')
        else
          history_dialog = '<div id="history_dialog" title="History Information"></div>'
          $('body').append(history_dialog)
          $("#history_dialog").html(history_dialog_content)
          #$('#history_dialog').append(history_dialog_content)
          $('#history_dialog').dialog
            autoOpen: false
            minWidth: 600
            position: { my: "right top", at: "right top", of: window }
          $('#history_dialog').dialog('open')

    error: (response) ->
      std_msg_error("<p>Something went wrong: #{response.responseText}","")
  , this)

window.drop_current_categories = () ->

  urls = []

  for i in [1 .. 5]
    urls.push($("#url_" + i ).val())

  std_msg_ajax(
    url:'/escalations/api/v1/escalations/webcat/complaints/drop_current_categories'
    method: 'POST'
    data: { 'urls': urls }
    success: (response) ->
      std_msg_success('Categories have been successfully dropped.', [], reload: false)
    error: (response) ->
      std_msg_error("<p>There has been an error dropping categories: #{json.error}","")
)

format = (complaint_entry_row) ->
  complaint_entry = complaint_entry_row.data()
  row_id = complaint_entry_row[0][0]
  missing_data = '<span class="missing-data">No Data</span>'
  uri = ''
  host = ''
  url = ''
  search_uri = ''
  if complaint_entry.uri
    uri = '<a href="http://' + complaint_entry.uri + '" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + complaint_entry.uri + '</a>'
    search_uri = '<a href="https://www.google.com/search?q=site%3A+' + complaint_entry.uri + '" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + complaint_entry.uri + '</a>'
  else if complaint_entry.domain
    if complaint_entry.subdomain
      host = complaint_entry.subdomain + '.'
    host = host + complaint_entry.domain
    url = host
    if complaint_entry.path
      url = host
    uri = '<a href="http://' + url + '" target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + url + '</a>'
    search_uri = '<a href="https://www.google.com/search?q=site%3A+' + url + '" target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + url + '</a>'
  else if  complaint_entry.ip_address
    host = complaint_entry.ip_address
    url = host
    uri = '<a href="http://' + complaint_entry.ip_address + '" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + complaint_entry.ip_address + '</a>'
    search_uri = '<a href="https://www.google.com/search?q=site%3A+' + complaint_entry.ip_address + '" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + complaint_entry.ip_address + '</a>'
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

  customer_description = ''
  if complaint_entry.description
    customer_description = complaint_entry.description
  else
    customer_description = missing_data

  screen_shot_error = ''
  if complaint_entry.screen_shot_error
    screen_shot_error = complaint_entry.screen_shot_error

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
  internal_comment=''
  if complaint_entry.internal_comment
    internal_comment = complaint_entry.internal_comment
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
      when "UNCHANGED"
        unchanged_radio = "checked='checked'"
      when "FIXED"
        fixed_radio = "checked='checked'"
      when "INVALID"
        invalid_radio = "checked='checked'"
  else
    fixed_radio = "checked='checked'"
  if complaint_entry.current_categories?
    categories = complaint_entry.current_categories
    category_table = ''
    category_row = ''
    tooltip_table = ''
    tooltip_all = ''
    tooltip_wrapper_start = '<div class="tooltip_templates"><span id="'
    tooltip_table_start = '<table class="category-tooltip-table"><thead><tr><th>Certainty</th><th>Category</th><th>Source</th></tr></thead><tbody>'
    tooltip_table_end = '</tbody></table>'
    tooltip_table_guts = ''
    tooltip_wrapper_end = '</span></div>'
    $.each categories, (key, value) ->
      category = this
      active =  $(this).attr("is_active")
      if active == 1
        confidence = this.confidence
        mnemonic = this.mnemonic
        name = this.name
        cat_id = this.category_id
        top_certainty = this.certainty[0].source_certainty
        certainties = this.certainty
        $(certainties).each ->
          source_certainty = this.source_certainty
          source_category = this.source_category
          source_name = this.source
          certainty_row = '<tr><td>' + source_certainty + '</td><td>' + source_category + '</td><td>' + source_name + '</td></tr>'
          tooltip_table_guts = tooltip_table_guts + certainty_row

        tooltip_table = tooltip_table_start + tooltip_table_guts + tooltip_table_end
        tooltip_all = tooltip_wrapper_start + 'certainty_table' + complaint_entry.entry_id + '_' +cat_id + '">' + tooltip_table + tooltip_wrapper_end
        category_row = '<tr><td>' + confidence + '</td><td>' + mnemonic + '</td><td>' + name + '</td><td><span class="nested-tooltipped certainty-flag" onmouseover="triggerTooltips(this)" data-tooltip-content="#certainty_table' + complaint_entry.entry_id + '_' +cat_id + '">' + top_certainty + '</span>' + tooltip_all + '</td></tr>'
        category_table = category_table + category_row

      return

  if complaint_entry.entry_history?
    if complaint_entry.entry_history.domain_history.length >= 1
      domain_history = complaint_entry.entry_history.domain_history
    else
      domain_history = ''
    if complaint_entry.entry_history.complaint_history.length >= 1
      complaint_history = complaint_entry.entry_history.complaint_history
    else
      complaint_history = ''

  whois_lookup = if complaint_entry.ip_address then complaint_entry.ip_address else complaint_entry.domain


  complaint_entry_html = ''
  if complaint_entry.status == "PENDING"
    input_cat = 'input_cat_' + complaint_entry.entry_id
    complaint_entry_html = '<table><tr><td class="no_pad"><div class="row">' +
      '<div class="col-xs-12 col-sm-6 nested-complaint-static-data">' +
      '<div class="row">' +
      '<div class="col-xs-5 col-with-divider">' +
      '<div class="screenshot-thumb-wrapper">' +
      '<img id="screenshot_id_' + complaint_entry.entry_id + '" class="screenshot-thumb-img" title="' + screen_shot_error + '" data-toggle="popover" onclick="enlarge_image(' + complaint_entry.entry_id + ',\'complaint_entries/serve_image?complaint_entry_id=' + complaint_entry.entry_id + '\')" src="complaint_entries/serve_image?complaint_entry_id=' + complaint_entry.entry_id + '" />' +
      '</div>' +
      '<div class="complaint-entry-info">' +
      '<label class="content-label-sm">Case ID</label>' +
      '<span class="nested-complaint-data case-id"><a href="complaints/' + complaint_entry.complaint_id + '">' + complaint_entry.complaint_id + '</a></span>' +
      '<label class="content-label-sm">Entry URI</label>' +
      '<span class="nested-complaint-data">' + url + '</span>' +
      '<label class="content-label-sm">Site Search</label>' +
      '<span class="nested-complaint-data">' + search_uri + '</span>' +
      '</div></div>' +
      '<div class="col-xs-5 col-with-divider">' +
      '<table class="simple-nested-table"><thead><tr><th>Conf</th><th colspan="2">Current Categories</th><th>Certainty</th></tr></thead>' +
      '<tbody>' + category_table +
      '</tbody></table>' +
      '</div>' +
      '<div class="col-xs-2">' +
      '<label class="content-label-sm">Resolution</label><br/>' +
      '<span class="complaint-resolution' + complaint_entry.entry_id + '">' + complaint_entry.resolution + '</span>' +
      '</div></div></div>' +
      '<div class="col-xs-12 col-sm-6 nested-complaint-editable-data">' +
      '<div class="row">' +
      '<div class="col-xs-6 col-with-divider">' +
      '<label class="content-label-sm">Edit URI</label><br/>' +
      '<input class="nested-table-input" id="complaint_prefix_' + complaint_entry.entry_id +
      '" type="text" onclick="this.select()" value="' + host +
      '"' + entry_status + '>' +
      '<button class="secondary inline-button" onclick="removeSubdomain(complaint_prefix_' + complaint_entry.entry_id +
      ',\'' + complaint_entry.domain + '\')"' + entry_status + '>Remove Subdomain</button><br/>' +
      '<div class="complaint-selectize-col-wrapper">' +
      '<label class="content-label-sm">Categories to commit</label>' +
      '<fieldset id="'+input_cat+'" ' + entry_status + '  name="['+input_cat+'][]" class="selectize" placeholder="Enter up to 5 categories" value="">' +
      '</div></div>' +
      '<div class="col-xs-4 col-with-divider">' +
      '<label class="content-label-sm">Internal Comment</label><br/>' +
      '<input class="nested-table-input complaint-comment-input" id="complaint_comment_' + complaint_entry.entry_id + '" type="text" onclick="this.select()" class="nested-table-input" value="' + internal_comment + '" placeholder="Add a comment." ' + entry_status + '><br/>'  +
      '<label class="content-label-sm customer-label">Customer Facing Comment</label><br/>' +
      '<input class="nested-table-input complaint-comment-input" id="complaint_resolution_comment_' + complaint_entry.entry_id + '" type="text" onclick="this.select()" value="' + resolution_comment + '" placeholder="Add a comment for the customer." ' + entry_status + '>' +
      '</div>' +
      '<div class="col-xs-2">' +
      '<input type="radio" name="resolution_review_' + complaint_entry.entry_id + '" value="commit" > Commit <br/>' +
      '<input type="radio" name="resolution_review_' + complaint_entry.entry_id + '" value="decline" checked="checked"> Decline' +
      '<br/><button class="tertiary" onclick="updatePending(' + complaint_entry.entry_id + ',' + row_id + ')"> Submit </button>' +
      '</div></div>' +
      '</div></div></td></tr></table>'

  else
    input_cat = 'input_cat_' + complaint_entry.entry_id

    complaint_entry_html = '<table><tr><td class="no_pad"><div class="row"><div class="col-xs-12 col-sm-6 nested-complaint-static-data">' +
      '<div class="row">' +
      '<div class="col-xs-5 col-with-divider">' +
      '<div class="screenshot-thumb-wrapper">' +
      '<img id="screenshot_id_' + complaint_entry.entry_id + '" class="screenshot-thumb-img" title="' + screen_shot_error + '" data-toggle="popover" onclick="enlarge_image(' + complaint_entry.entry_id + ',\'complaint_entries/serve_image?complaint_entry_id=' + complaint_entry.entry_id + '\')" src="complaint_entries/serve_image?complaint_entry_id=' + complaint_entry.entry_id + '" />' +
      '</div>' +
      '<div class="complaint-entry-info">' +
      '<label class="content-label-sm">Case ID</label>' +
      '<span class="nested-complaint-data case-id"><a href="complaints/' + complaint_entry.complaint_id + '">' + complaint_entry.complaint_id + '</a></span>' +
      '<label class="content-label-sm">Entry URI</label>' +
      '<span class="nested-complaint-data">' + uri + '</span>' +
      '<label class="content-label-sm">Site Search</label>' +
      '<span class="nested-complaint-data">' + search_uri + '</span>' +
      '<label class="content-label-sm">Customer Description</label>' +
      '<span class="nested-complaint-data">' + customer_description + '</span>' +
      '</div></div><div class="col-xs-5 col-with-divider">' +
      '<table class="simple-nested-table"><thead><tr><th>Conf</th><th colspan="2">Current Categories</th><th>Certainty</th></tr></thead>' +
      '<tbody>' + category_table +
      '</tbody></table>' +
      '</div><div class="col-xs-2">' +
      '<button class="secondary">Lookup</button><br/>' +
      '<button class="secondary" onclick="history_dialog(' + complaint_entry.entry_id  + ')">History</button><br/>' +
      '<button class="secondary" onclick="domain_whois(\'' + whois_lookup + '\')">Domain</domain>' +
      '</div></div>' +
      '</div><div class="col-xs-12 col-sm-6 nested-complaint-editable-data">' +
      '<div class="row">' +
      '<div class="col-xs-6 col-with-divider">' +
      '<label class="content-label-sm">Edit URI</label><br/>' +
      '<input class="nested-table-input" id="complaint_prefix_' + complaint_entry.entry_id +
      '" type="text" onclick="this.select()" value="' + host +
      '"' + entry_status + '>' +
      '<button class="secondary inline-button" onclick="removeSubdomain(complaint_prefix_' + complaint_entry.entry_id +
      ',\'' + complaint_entry.domain + '\')"' + entry_status + '>Remove Subdomain</button><br/>' +
      '<div class="complaint-selectize-col-wrapper">' +
      '<label class="content-label-sm">Edit Categories / Confidence Order</label>' +
      '<fieldset id="'+input_cat+'" ' + entry_status + '  name="['+input_cat+'][]" class="selectize" placeholder="Enter up to 5 categories" value="">' +
      '</div></div><div class="col-xs-4 col-with-divider">' +
      '<label class="content-label-sm">Internal Comment</label><br/>' +
      '<input class="nested-table-input complaint-comment-input" id="complaint_comment_' + complaint_entry.entry_id + '" type="text" onclick="this.select()" class="nested-table-input" value="' + internal_comment + '" placeholder="Add a comment." ' + entry_status + '><br/>'  +
      '<label class="content-label-sm customer-label">Customer Facing Comment</label><br/>' +
      '<input class="nested-table-input complaint-comment-input" id="complaint_resolution_comment_' + complaint_entry.entry_id + '" type="text" onclick="this.select()" value="' + resolution_comment + '" placeholder="Add a comment for the customer." ' + entry_status + '>' +
      '</div><div class="col-xs-2">' +
      '<label class="content-label-sm">Resolution</label><br/>' +
      '<input type="radio" id="unchanged' + complaint_entry.entry_id + '" name="resolution' + complaint_entry.entry_id + '" value="UNCHANGED" ' + unchanged_radio + entry_status + '> Unchanged <br/> ' +
      '<input type="radio" id="fixed' + complaint_entry.entry_id + '" name="resolution' + complaint_entry.entry_id + '" value="FIXED"  ' + fixed_radio + entry_status + '> Fixed  <br/> ' +
      '<input type="radio" id="invalid' + complaint_entry.entry_id + '" name="resolution' + complaint_entry.entry_id + '" value="INVALID" ' + invalid_radio + entry_status + '> Invalid' +
      '<br/>' +
      '<button class="tertiary" id="submit_changes_' + complaint_entry.entry_id + '" onclick="updateEntryColumns(' + complaint_entry.entry_id + ',' + row_id + ')" ' + entry_status + '>Submit Changes</button>' +
      '</div></div></div></div></div></td></tr></table>'

  complaint_entry_html

window.history_dialog = (id) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/history'
    method: 'POST'
    headers: headers
    data: {'id': id}
    success: (response) ->
      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        alert(json.error)
      else
        #parse this json properly
        history_dialog_content = '<div class="dialog-content-wrapper">' +
          '<h5>Domain History</h5>' +
          '<table class="history-table"><thead><tr><th>Action</th><th>Confidence</th><th>Description</th><th>Time</th><th>User</th><th>Category</th></tr></thead>' +
          '<tbody>'
        for entry in json.entry_history.domain_history
          entry_string = "" +
          '<tr>' +
          '<td>' + entry['action'] + '</td>' +
          '<td>' + entry['confidence'] + '</td>' +
          '<td>' + entry['description'] + '</td>' +
          '<td>' + entry['time'] + '</td>' +
          '<td>' + entry['user'] + '</td>' +
          '<td>' + entry['category']['descr'] + '</td>' +
          '</tr>'

          history_dialog_content += entry_string
        history_dialog_content += '</tbody></table>'
        history_dialog_content += '<hr class="thin"/>'
        history_dialog_content += '<h5>Complaint Entry History</h5>'
        entry_string = ""
        for key, entry of json.entry_history.complaint_history

          entry_string = "" +
          '<p>Time: ' + key + '</p>'
          for change_key, change_entry of entry
            if change_key != "whodunnit"
              entry_string += "<p>" + change_key + ": " + change_entry[0] + " - " + change_entry[1] + "</p>"
            else
              entry_string += "<p>User: " + change_entry + "</p>"
          history_dialog_content += entry_string

        if $("#history_dialog").length
          history_dialog = this
          $("#history_dialog").html(history_dialog_content)
          $('#history_dialog').dialog('open')
        else
          history_dialog = '<div id="history_dialog" title="History Information"></div>'
          $('body').append(history_dialog)
          $("#history_dialog").html(history_dialog_content)
          #$('#history_dialog').append(history_dialog_content)
          $('#history_dialog').dialog
            autoOpen: false
            minWidth: 600
            position: { my: "right top", at: "right top", of: window }
          $('#history_dialog').dialog('open')
#        dialog_content = $(format_domain_info(json))
#        if $("#complaint_button_dialog").length
#          complaint_dialog = this
#          $('#complaint_button_dialog').html(dialog_content[0])
#        else
#          complaint_dialog = '<div id="complaint_button_dialog" title="Domain Information"></div>'
#          $('body').append(complaint_dialog)
#          $('#complaint_button_dialog').append(dialog_content[0])
#          $('#complaint_button_dialog').dialog
#            autoOpen: true
#            minWidth: 400
#            position: { my: "right bottom", at: "right bottom", of: window }
    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)




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
  if !filter
    filter = "NEW"

  if $('body.index-action').length
    self_review = $('#self_review')[0].checked
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries?filter_by='+filter+'&self_review='+self_review
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
    url: '/escalations/api/v1/escalations/webcat/complaints/test_url'
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

window.fetch_wbnp_data = () ->
  $('#loader-modal').modal({
    backdrop: 'static',
    keyboard: false
  })
  std_msg_ajax(
    method: 'POST'
    url: '/escalations/api/v1/escalations/webcat/complaints/fetch_wbnp_data'
    data: {}
    success: (response) ->
      $('#loader-modal').hide()
      std_msg_success('WBNP Complaints successfully retrieved from RuleUI.', [], reload: true)
    error: (response) ->
      $('#loader-modal').hide()
      $('.modal-backdrop').remove()
      std_api_error(response, 'Error fetching wbnp data complaints.', reload: false)
  )

window.fetch_complaints = () ->
  std_msg_ajax(
    method: 'POST'
    url: '/escalations/api/v1/escalations/webcat/complaints/fetch'
    data: {}
    success_msg: 'Complaint updates requested from Talos-Intelligence.  Please refresh your page shortly.'
    error_prefix: 'Error fetching complaints.'
  )


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
    url: '/escalations/api/v1/escalations/webcat/complaints/mark_for_commit'
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
    url: '/escalations/api/v1/escalations/webcat/complaints/commit_marked'
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
      complaint_id: $('#cat_named_search').find('input[id="complaintid-input"]').val().split(",")
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
    url: '/escalations/api/v1/escalations/webcat/complaint_entries'
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


window.load_screenshot = (img_tag, complaint_entry_id) ->
  std_msg_ajax(
    method: 'GET'
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/' + complaint_entry_id + '/screenshot'
    data: {}
    img_tag: img_tag
    error_prefix: 'Error downloading screenshot.'
    success: (response) ->
      JSON.parse(response).image_data
      image_data = JSON.parse(response).image_data
      src = 'data:image/png;base64,' + image_data
      this.img_tag.src = src
  )

window.triggerTooltips = () ->
  $('.nested-tooltipped').tooltipster
    theme: [
      'tooltipster-borderless'
      'tooltipster-borderless-customized'
    ]
    side: 'bottom'
  return

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

  $('#cat_new_url_modal').on 'shown.bs.modal', ->
    $('#url_1').focus()
    return

  $('#cat-urls-diff').click ->
    if $('#cat-urls-diff').prop('checked')
      $('#categorize-diff-form').show()
      $('#categorize-same-form').hide()

  $('#cat-urls-same').click ->
    if $('#cat-urls-same').prop('checked')
      $('#categorize-diff-form').hide()
      $('#categorize-same-form').show()




