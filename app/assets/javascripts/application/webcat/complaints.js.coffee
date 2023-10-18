table_page = 0

$(document).on 'click', '.paginate_button', ->
  complaint_table = $('#complaints-index').DataTable().context
  if complaint_table.length > 0
    table = $('#complaints-index').DataTable()
    table_page = table.page.info().page



init_tooltip = () ->
  $('.esc-tooltipped:not(.tooltipstered)').tooltipster
    theme: [
      'tooltipster-borderless'
      'tooltipster-borderless-customized'
    ]



# Below edge case I'm unsure of is removing a category and adding a new one,
# or adding and then removing the same one
# Consulting Adam on this one

# Store changes in local storage to see if Bulk Submit can be used
# call this when resolution is changed or a cat is added
window.store_entry_changes = (entry_id) ->
  changes = (sessionStorage.getItem("webcat_entries_changed") || "")
  unless changes.includes(entry_id)
    entries = changes.split(",").filter((item) -> return item)
    entries.push(entry_id)
    new_changes = entries.join(",")
    sessionStorage.setItem("webcat_entries_changed", new_changes)


# If user submits individual entry, remove it from the local storage changes
window.remove_entry_from_changes = (entry_id) ->
  changes = (sessionStorage.getItem("webcat_entries_changed") || "")
  if changes.includes(entry_id)
    entries = changes.split(",").filter((item) -> return item)
    submitted_entry = entries.indexOf(entry_id)
    new_changes = entries.splice(submitted_entry, 1)
    sessionStorage.setItem("webcat_entries_changed", new_changes)

# remove below after updating the submit pending functions
#window.removeTouchedFormChange = (url) ->
#  urls_touched = (sessionStorage.getItem("touchedForm")|| "" )
#  if urls_touched.includes(url)
#    url_items = urls_touched.split(",")
#    url_items = url_items.filter((item) -> return item)
#    url_index = url_items.indexOf(url)
#    url_items.splice(url_index, 1)
#    urls_touched = url_items.join(",")
#  sessionStorage.setItem("touchedForm", urls_touched)

# we may not need this
getTouchedFormCount = ()->
  form_item = (sessionStorage.getItem("webcat_entries_changed") || "")
  form_item = form_item.split(",")
  form_item = form_item.filter((item) -> return item)
  return form_item.length




# TODO - fix this function
# New layout does not save this separately from submitting the updates, need to rethink how this is done
# pretty sure this is not needed
#window.updateURI = (event, complaint_entry_id) ->
#  event.preventDefault()
#
#  uri = $("#complaint_prefix_#{complaint_entry_id}").val()
#
#  std_msg_ajax(
#    method: 'POST'
#    url: "/escalations/api/v1/escalations/webcat/complaints/update_uri"
#    data: {complaint_entry_id: complaint_entry_id, uri: uri }
#    success: (response) ->
#      {current_categories, category, wbrs_score, domain, subdomain, path, status} = response.json
#
#      if subdomain
#        qual_subdomain = subdomain + '.' + domain
#      else
#        qual_subdomain = domain
#
#      $(".simple-nested-table#entry-table-#{complaint_entry_id} tbody > tr").remove()
#
#      if 'ip' == status
#        std_msg_error("Cannot edit IP entries.","")
#      else
#        $("#domain_#{complaint_entry_id}").tooltipster('content', uri);
#        $("#site-search-#{complaint_entry_id}").tooltipster('content', uri);
#        $("#entry-uri-#{complaint_entry_id}").tooltipster('content', uri);
#        $.each current_categories, (key, entry) ->
#          $(".simple-nested-table#entry-table-#{complaint_entry_id}").append("<tr><td>#{entry.confidence}</td><td>#{entry.mnem} - #{entry.descr}</td><td>#{entry.top_certainty}</span></td></tr>")
#
#        $("#domain_#{complaint_entry_id}").text(domain)
#        $("#subdomain_#{complaint_entry_id}").text(subdomain)
#        $("#path_#{complaint_entry_id}").text(path)
#        $("#category_#{complaint_entry_id}").text(category)
#        $("#wbrs_score_#{complaint_entry_id}").text(wbrs_score)
#        query_who_params = "#{domain}, #{complaint_entry_id}"
#        $("#entry-uri-#{complaint_entry_id}").html("<a href='http://#{uri}' target='_blank' onclick='select_cat_text_field(#{complaint_entry_id})' >#{uri}</a>")
#        $("#site-search-#{complaint_entry_id}").html("<a href='https://www.google.com/search?q=site%3A#{uri}' target='_blank' onclick='select_cat_text_field(#{complaint_entry_id})'>#{uri}</a>")
#
#        $("#lookup-#{complaint_entry_id}").replaceWith('<button class="secondary" id="lookup-' + complaint_entry_id + '" data-fqdn="' + qual_subdomain + '" onclick="WebCat.RepLookup.whoIsLookups(' + complaint_entry_id  + ',\'' + qual_subdomain + '\')">Whois</button>')
#        $("#history-#{complaint_entry_id}").replaceWith('<button class="secondary" id="history-' + complaint_entry_id + '" onclick="history_dialog(' + complaint_entry_id + ',\'' + uri + '\')">History</button>')
#    error: (response) ->
#      std_msg_error("Unable to update URI", [response.responseJSON.message], reload: false)
#
# )



window.webcat_reset_search = ()->
  inputs = document.getElementsByClassName('form-control')
  for i in inputs
    i.value = ""

  tag_input = $('#tags-input')[0].selectize
  assignee_input = $('#assignee-input')[0].selectize
  category_input = $('#category-input')[0].selectize
  company_input = $('#company-input')[0].selectize
  status_input = $('#status-input')[0].selectize
  resolution_input = $('#resolution-input')[0].selectize
  customer_input = $('#name-input')[0].selectize
  complaint_input = $('#complaint-input')[0].selectize
  channel_input = $('#channel-input')[0].selectize
  entry_input = $('#entryid-input')[0].selectize
  complaint_id_input = $('#complaintid-input')[0].selectize

  tag_input.clear()
  assignee_input.clear()
  category_input.clear()
  company_input.clear()
  status_input.clear()
  resolution_input.clear()
  customer_input.clear()
  complaint_input.clear()
  channel_input.clear()
  entry_input.clear()
  complaint_id_input.clear()


#TODO - when do we use this
window.inheritCategories = (complaint_entry_id) ->
  std_msg_ajax(
    url:'/escalations/api/v1/escalations/webcat/complaint_entries/inherit_categories_from_master_domain'
    method: 'POST'
    data: {'id': complaint_entry_id}
    success: (response) ->
      $('.domain-categories').hide()
      std_msg_success('Success',["Successfully inherited categories from main domain."], reload: false)

    error: (response) ->
      std_msg_error('Error' + ' ' + response.responseJSON.message,"", reload: false)
    )

# TODO - what is this for
name_servers =(server_list)->
  if undefined == server_list
    ''
  else
    text = ""
    for server in server_list
      text += server + '<br>'
    text

# TODO - what is this for
format_domain_info = (info)->
  '<div class="dialog-content-wrapper">' +
    '<h5>Domain Name</h5>' +
    '<p>' + info['domain'] + '</p>' +
    '<hr class="thin">' +
    '<h5>Registrant </h5>' +
    '<table class="nested-dialog-table">' +
      '<tr>' +
        '<td class="table-side-header">' +
           'Organization' +
        '</td>' +
        '<td>' +
          info['organisation'] +
      '</tr><tr>' +
        '<td class="table-side-header">' +
          'Country' +
        '</td>' +
        '<td>' +
          info['registrant_country'] +
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
    name_servers(info['nserver']) +
    '<hr class="thin">' +
    '<h5> Dates</h5>'+
    '<table class="nested-dialog-table">' +
      '<tr>' +
        '<td class="table-side-header">' +
          'Created' +
        '</td>' +
        '<td>' + info['created'] + '</td>'+
      '</tr><tr>' +
        '<td class="table-side-header">' +
          'Last updated' +
        '</td>' +
        '<td>' +
          info['changed'] +
        '</td>' +
      '</tr><tr>' +
        '<td class="table-side-header">' +
          'Expiry_date' +
        '</td>' +
        '<td>' +
          info['registry_expiry_date'] +
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
      info = $.parseJSON(response)
      if info.error
        notice_html = "<p>Something went wrong: #{info.error}</p>"
        alert(info.error)
      else
        dialog_content = $(format_domain_info(info))
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


window.review_bulk_submit = () ->
  selected_rows = $("tr.highlight-second-review.shown")
  self_review = $('#self_review').is(':checked')
  if selected_rows.length < 1
    return
  entries_to_update = []
  selected_rows.each ->
    entry_id = this.id
    prefix = $('#complaint_prefix_'+entry_id)[0].value
    status = $('[name=resolution_review_'+entry_id+']:checked').val()
    comment = $('#complaint_comment_'+entry_id)[0].value
    resolution_comment = $('#complaint_resolution_comment_'+entry_id)[0].value
    resolution = $('.complaint-resolution'+entry_id).text()
    #get the selectize control for the category input
    selectizeControl = $('#input_cat_'+entry_id).selectize()[0].selectize
    if $('#input_cat_'+entry_id).val() == null
      categories = null
    else
      categories = $('#input_cat_'+entry_id).val().toString()

    named_categories = ""
    if categories == null
      cat_array = []
    else
      cat_array = categories.split(',')
      for cat, i in cat_array
        named_categories = named_categories + selectizeControl.getItem(cat).text()
        if i < cat_array.length
          named_categories += ", "
    if status != "ignore"
      entries_to_update.push({
        'self_review': self_review,
        'id': entry_id,
        'prefix': prefix,
        'commit':status,
        'status':resolution,
        'comment':comment,
        'resolution_comment': resolution_comment,
        'categories': categories,
        'category_names':named_categories
      })

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/update_pending'
      method: 'POST'
      data: {data: entries_to_update}
      success: (response) ->
        window.location.reload(false);
      error: (response) ->
        notice_html = "<p>Something went wrong</p>"
    , this)



processSubmitPending=(entry_id,row_id)->
  prefix = $('#complaint_prefix_'+entry_id)[0].value
  status = $('[name=resolution_review_'+entry_id+']:checked').val()
  if status == "ignore"
    alert("Because the 'Ignore' radio is checked, this operation did nothing")
    return
  comment = $('#complaint_comment_'+entry_id)[0].value
  resolution_comment = $('#complaint_resolution_comment_'+entry_id)[0].value
  resolution = $('.complaint-resolution'+entry_id).text()
  self_review = $('#self_review').is(':checked')

  #get the selectize control for the category input
  selectizeControl = $('#input_cat_'+entry_id).selectize()[0].selectize
  if $('#input_cat_'+entry_id).val() == null
    categories = null
  else
    categories = $('#input_cat_'+entry_id).val().toString()

  named_categories = ""
  if categories == null
    cat_array = []
  else
    cat_array = categories.split(',')
    for cat, i in cat_array
      named_categories = named_categories + selectizeControl.getItem(cat).text()
      if i < cat_array.length
        named_categories += ", "

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/update_pending'
    method: 'POST'
    data: {
      data: [{
        'self_review': self_review,
        'id': entry_id,
        'prefix': prefix,
        'commit':status,
        'status':resolution,
        'comment':comment,
        'resolution_comment': resolution_comment,
        'categories': categories,
        'category_names':named_categories
      }]
    }
    success: (response) ->
      {uri, domain, subdomain, path, categories, error, entry_id, was_dismissed, status} = $.parseJSON(response)
      if error
        notice_html = "<p>Something went wrong: #{error}</p>"
        alert(error)
      else
        table = $('#complaints-index').DataTable()
        temp_row = table.row(row_id)
        td = $(temp_row).next('tr').find('td:first')
        unless $(td).hasClass 'nested-complaint-data-wrapper'
          $(td).addClass 'nested-complaint-data-wrapper'
        if was_dismissed
          temp_row.node().className += ' highlight-was-dismissed'
        temp_row.data().uri = uri
        temp_row.data().category = categories
        temp_row.data().status = status
        temp_row.data().resolution = resolution
        temp_row.data().internal_comment = comment
        temp_row.data().resolution_comment = resolution_comment
        temp_row.invalidate().page(table_page).draw(false)
        temp_row.child().remove()
        temp_row.child(format(temp_row)).show()
        nested_tooltip()
        $('#input_cat_'+ temp_row.data().entry_id).selectize {
          persist: false,
          create: false,
          maxItems: 5,
          closeAfterSelect: true,
          valueField: 'category_id',
          labelField: 'category_name',
          searchField: ['category_name', 'category_code'],
          options: AC.WebCat.createSelectOptions('#input_cat_'+ temp_row.data().entry_id),
          items: selected_options(temp_row.data().category)
        }
        $("#domain_#{entry_id}").text(domain)
        $("#subdomain_#{entry_id}").text(subdomain)
        $("#path_#{entry_id}").text(path)
        removeTouchedFormChange(uri)
        timesTouched = 0

      tds = $('#complaints-index tbody').closest('td')
      for td in tds
        if td.className == ''
          td.classList.add('nested-complaint-data-wrapper')
    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)

window.updatePending = (id,row_id) ->
  timesTouched = getTouchedFormCount()
  if timesTouched > 1
    std_msg_confirm(
      "You have made " + timesTouched + " changes on this page. Do you want to proceed with updating this pending item? It will reload the page and you will lose your changes.",
      [],
      {
        reload: false,
        confirm_dismiss: true,
        confirm: ->
          processSubmitPending(id,row_id)
      })
  else
    processSubmitPending(id,row_id)




## Allows analyst to set ticket status to reopened and allows them to interact with the submission form
window.reopenComplaint = (entry_id, button) ->

# Getting all the fields that need to be interactive if reopened
  # Changing these on the fly so the full page doesn't need to be reloaded
  editable_stuff = $(button).parents('.nested-complaint-editable-data')[0]
  inputs = $(editable_stuff).find('.nested-table-input')
  radios = $(editable_stuff).find('.resolution_radio_button')
  wrapper = $(button).parents('.nested-complaint-data-wrapper')[0]
  nested_row = $(wrapper).parents('tr')[0]
  parent_row = $(nested_row).prev()
  status_col = $(parent_row).find('.state-col')

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/reopen_complaint_entry'
    method: 'POST'
    data: {'complaint_entry_id': entry_id}
    success: (response) ->
      $(inputs).each ->
        $(this).prop('disabled', false)
      $(radios).each ->
        $(this).prop('disabled', false)
      select_input =   $('#input_cat_' + entry_id)[0].selectize
      select_input.enable()
      $("#reopen_" + entry_id).addClass('hidden')
      $("#submit_changes_" + entry_id).removeClass('hidden')
      $(status_col).text('REOPENED')
    error: (response) ->
      std_msg_error(response,"", reload: false)
  )





# TODO - check this function
$(document).on 'click', '#complaints-index tr, #complaints_check_box, #complaints_select_all', ->
  rows = $('#complaints-index').DataTable().rows('.selected').data()
  reopened = false
  invalid_unchanged = false
  disabled = true
  for row in rows
    { status } = row

    if status == 'COMPLETED'
        reopened = true
        disabled = false
    if  status == 'RESOLVED' || status == 'NEW' || status == 'ASSIGNED'|| status == 'REOPENED'
        invalid_unchanged = true
        disabled = false

  if disabled == false
    $('#index_update_resolution').attr('disabled', false)
  else
    $('#index_update_resolution').prop('disabled', disabled)

  reopened_opt = $('#complaint_resolution option:contains("Reopened")')
  invalid_opt = $('#complaint_resolution option:contains("Invalid")')
  unchanged_opt = $('#complaint_resolution option:contains("Unchanged")')

  if !reopened
    reopened_opt.attr("disabled","disabled");
  else
    reopened_opt.removeAttr("disabled");
    reopened_opt.prop('selected', true)

  if !invalid_unchanged
    invalid_opt.attr("disabled","disabled");
    unchanged_opt.attr("disabled","disabled");
  else
    invalid_opt.removeAttr("disabled");
    unchanged_opt.removeAttr("disabled");
    invalid_opt.prop('selected', true)

  comment_check()


$(document).on 'change','#complaint_resolution', ->
  internal_comment = $('.internal_comment_container')
  customer_comment = $('.customer_facing_comment_container')
  if $(this).val() == 'REOPENED'
    internal_comment.css('display', 'none')
    customer_comment.css('display', 'none')
  else
    internal_comment.css('display', 'block')
    customer_comment.css('display', 'block')

window.comment_check = ()->
  invalid_opt = $('#complaint_resolution option:contains("Invalid"):not(:disabled)').length == 1
  reopened_opt = $('#complaint_resolution option:contains("Reopened"):not(:disabled)').length == 1
  internal_comment = $('.internal_comment_container')
  customer_comment = $('.customer_facing_comment_container')
  if reopened_opt && invalid_opt || invalid_opt
    internal_comment.css('display', 'block')
    customer_comment.css('display', 'block')
  else
    internal_comment.css('display', 'none')
    customer_comment.css('display', 'none')




selected_options = (category_names) ->
  options = []
  if category_names
    options = category_names.split(',')

    #splice together 'Conventions, Conferences and Trade Shows' due to extra comma
    if category_names.includes('Conferences and Trade Shows')
      $(options).each (i, category) ->
        if category == 'Conventions'
          options.splice(i, 1)
        else if category == ' Conferences and Trade Shows'
          i2 = i - 1
          options.splice(i2, 1, 'Conventions, Conferences and Trade Shows')
  return options


#$(document).on 'click', ".popover .screenshot-retake-button", ->
#  $('[data-original-title]').popover 'hide'
#  se_id = this.id.slice(6)
#  std_msg_ajax(
#    method: 'GET'
#    url: '/escalations/api/v1/escalations/webcat/complaint_entries/' + se_id + '/retake_screenshot'
#    data: {}
#    error_prefix: 'Error retaking screenshot.'
#    success: (response) ->
#      std_msg_success('Screenshot job initiated. Check back in about 10 seconds.', [], reload: true)
#  )



#window.fill_qual_subdomain =(anchor_tag, input_id, qual_subdomain) ->
#  event.preventDefault();
#  $('#' + input_id)[0].value = qual_subdomain
#  return false;

# what is this for
#format = (complaint_entry_row) ->
#  complaint_entry = complaint_entry_row.data()
#  row_id = complaint_entry_row[0][0]
#
#  if complaint_entry.uri
#    host = complaint_entry.uri
#    url = host
#    uri = '<a href="http://' + complaint_entry.uri + '"  target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + complaint_entry.uri + '</a>'
#    uri_no_path = complaint_entry.uri
#    qual_subdomain = complaint_entry.domain
#    lookup_val = complaint_entry.domain
#    if uri_no_path.indexOf('/') > 0
#      uri_no_path = uri_no_path.split('/')[0] # strip out the path in a uri for Site Search, it's extraneous
#    search_uri = '<a href="https://www.google.com/search?q=site%3A' + uri_no_path + '" target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + uri_no_path + '</a>'
#  else if complaint_entry.domain
#    if complaint_entry.subdomain
#      host = complaint_entry.subdomain + '.'
#    host = host + complaint_entry.domain
#    url = host
#    if complaint_entry.path
#      url = host
#    uri = '<a href="http://' + url + '" target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + url + '</a>'
#    search_uri = '<a href="https://www.google.com/search?q=site%3A' + url + '" target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + url + '</a>'
#    lookup_val = complaint_entry.domain
#  else if  complaint_entry.ip_address
#    host = complaint_entry.ip_address
#    url = host
#    lookup_val = complaint_entry.ip_address
#    uri = '<a href="http://' + complaint_entry.ip_address + '"  target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + complaint_entry.ip_address + '</a>'
#    search_uri = '<a href="https://www.google.com/search?q=site%3A' + complaint_entry.ip_address + '" target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + complaint_entry.ip_address + '</a>'
#  else
#    uri = missing_data
#  if complaint_entry.subdomain
#    qual_subdomain = complaint_entry.subdomain + '.' + qual_subdomain
#    lookup_val = complaint_entry.subdomain + '.' + qual_subdomain
#
#  entry_status = ""
#  reopen_class = "hidden"
#  submit_class = ""
#  status_class = ""
#
#
#  if complaint_entry.entry_history?
#    if complaint_entry.entry_history.complaint_history.length >= 1
#      complaint_history = complaint_entry.entry_history.complaint_history
#    else
#      complaint_history = ''
#
#  { entry_id, domain, complaint_id, ip_address } = complaint_entry
#  whois_lookup = if ip_address then ip_address else domain
#  complaint_entry_html = ''
#  input_cat = 'input_cat_' + entry_id
#
#  if complaint_entry.status == "PENDING"
#    if complaint_entry.uri_as_categorized  == ""
#      # if a subdomain string exists, prepend it to the domain
#      if complaint_entry.subdomain.length > 0
#        domain = complaint_entry.subdomain + "." + complaint_entry.domain
#      else
#        domain = complaint_entry.domain
#    else
#      domain = complaint_entry.uri_as_categorized
#    # Wondering what the line above does? See here: https://jira.vrt.sourcefire.com/browse/WEB-5880
#
#  edit_input = if domain != "" then domain else host #if the domain is empty, then display host for ips in edit input
#
#
#  form_change_item = domain || complaint_entry.ip_address
#
#  complaint_entry_html =
#      complaint_table_row_html +
#
#      '<div><label class="content-label-sm">Original</label></div> ' +
#      '<div>' + host  + '</div>' +
#      '<label class="content-label-sm">Edit URI</label><br/>' +
#      '<input class="nested-table-input complaint-uri-input" id="complaint_prefix_' + entry_id +
#      '" type="text" data-domain="' + form_change_item + '" data-qual_subdomain="'+ qual_subdomain + '" value="' + edit_input +
#      '"' + entry_status + '>' +
#      '<button class="secondary inline-button" onclick="updateURI(event,' + entry_id + ')">Update URI</button><br/>' +
#      '<div><a href="#" onclick="fill_qual_subdomain(this, \'complaint_prefix_' + entry_id + '\', \''+ qual_subdomain + '\')">subdomain</a></div>' +
#
#      '<label class="content-label-sm">Inherit Categories From Main Domain</label><br/>' +
#      '<ul id="main-domain-categories_' + entry_id + '"></ul>'+
#      '<button class="secondary inline-button" onclick="inheritCategories(' + entry_id + ')">Inherit</button><br/>' +
#      '</div>' +'</div><div class="col-xs-8">' +
#      '<label class="content-label-sm customer-label">Customer Facing Comment</label><br/>' +
#      '<input class="nested-table-input complaint-comment-input" id="complaint_resolution_comment_' + entry_id + '" type="text" data-domain="' + domain + '" value="' + resolution_comment + '" placeholder="Add a comment for the customer." ' + entry_status + '>'






# Part of the screenshot code. Keeping for ref for when that is reimplemented
#window.display_preview_window = (entry) ->
#  {domain, category, id} = entry
#  $('#complaint_id_x_prefix')[0].value = domain
#  $('#complaint_id_x_categories')[0].value = category
#  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
#  #when checkbox is clicked take the domain and path and try to open it in the iframe
#  path = ""
#  subdomain = ""
#  if entry.subdomain
#    subdomain = entry.subdomain + "."
#  if entry.path
#    path = entry.path
#  loc = "http://" + subdomain + domain + path
#  $.ajax(
#    url: '/escalations/api/v1/escalations/webcat/complaints/test_url'
#    method: 'GET'
#    headers: headers
#    data: {
#      url:loc
#    }
#    success: (response) ->
#      #yay you can visit the site
#    error: (response) ->
#      #that page wont load. lets display someting else
#      switch response["status"]
#        when 404
#          document.getElementById('preview_window').src = "/unknown_url.html"
#        when 403
#          document.getElementById('preview_window').src = "/same_origin_url.html"
#
#  , this)
#
#  $(".complaint_selected" ).removeClass("complaint_selected")
#  $("#complaint_entry_row_"+ id ).addClass("complaint_selected")
#  document.getElementById('preview_window').src = loc
#  document.getElementById('preview_window_header_p').innerHTML = loc
#  document.getElementById('preview_window_header_a').href = loc



window.fetch_complaints = () ->
  std_msg_ajax(
    method: 'POST'
    url: '/escalations/api/v1/escalations/webcat/complaints/fetch'
    data: {}
    success_msg: 'Complaint updates requested from Talos-Intelligence.  Please refresh your page shortly.'
    error_prefix: 'Error fetching complaints.'
  )





# What does this do?
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

# what does this do?
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

window.triggerTooltips = (item) ->
  $('.nested-tooltipped').tooltipster
    theme: [
      'tooltipster-borderless'
      'tooltipster-borderless-customized'
    ]
    side: 'bottom'
  return

#bulk submit
processSubmitMaster = () ->
  debugger
  data = []
  selectedEntryDomains = (sessionStorage.getItem("webcat_entries_changed")|| "" )
  return if selectedEntryDomains.length == 0

  # disable the master submit button while processing
  $('#master-submit').prop('disabled', true)

  # remove empty values
  selectedEntryDomains = selectedEntryDomains.split(',').filter((item) -> item);
  selectedEntries = []
  self_review = $('#self_review').is(':checked')
  $('#complaints-index').DataTable().rows (idx, data, node) ->
    entry_item = data.domain || data.ip_address
    if selectedEntryDomains.includes(entry_item)
      selectedEntries.push data
    false
  for entry in selectedEntries
    data_wrapper = $("##{entry.entry_id}").closest('tr').next().find('.nested-complaint-data-wrapper')
    entry_id = data_wrapper.find('tr').attr('entry_id')
    row_id = data_wrapper.find('tr').attr('row_id')
    type = data_wrapper.find('tr').attr('type')

    if type == 'submit_changes' && entry_id && row_id
      prefix = data_wrapper.find("#complaint_prefix_#{entry_id}")[0].value

      category_names = []
      categories = ""
      if data_wrapper.find("#input_cat_#{entry_id}").val()
        categories = data_wrapper.find("#input_cat_#{entry_id}").val().toString()
      category_name = data_wrapper.find("#input_cat_#{entry_id}").next('.selectize-control').find('.item')
      category_name.each ->
        category_names.push($(this).text())
      category_names = category_names.toString()
      status = data_wrapper.find("[name=resolution#{entry_id}]:checked").val()
      comment = data_wrapper.find("#complaint_comment_#{entry_id}")[0].value
      resolution_comment = data_wrapper.find("#complaint_resolution_comment_#{entry_id}")[0].value
      uri_as_categorized = data_wrapper.find("#complaint_prefix_#{entry_id}")[0].value
      if (categories.length > 0 && status == 'FIXED') || ((categories.length == 0) && (status == 'INVALID' || status == 'UNCHANGED'))
        data.push({entry_id: entry_id, error: false, row_id: row_id, prefix: prefix, categories: categories, category_names: category_names, status: status, comment: comment, resolution_comment: resolution_comment, uri_as_categorized: uri_as_categorized})
      else if status == 'UNCHANGED' || status == 'INVALID'
        data.push({
          entry_id: entry_id,
          error: false,
          row_id: row_id,
          prefix: prefix,
          categories: categories,
          category_names: category_names,
          status: status,
          comment: comment,
          resolution_comment: resolution_comment,
          uri_as_categorized: uri_as_categorized,
          self_review: self_review
        })
      else if (categories.length == 0) && status == 'FIXED'
        data.push({entry_id, error: true, reason: 'nil_categories'})
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/webcat/complaint_entries/master_submit"
    data: {data: data}
    success: (response) ->
      errors = false

      nil_categories_errors = []
      api_errors = []
      success = []

      json = JSON.parse(response)

      table = $('#complaints-index').DataTable()

      for entry in json
        if entry.error == true && entry.reason == 'nil_categories'
          nil_categories_errors.push(entry.entry_id)
          errors = true
        else if entry.error == true && entry.reason == 'api'
          api_errors.push(entry.entry_id)
          errors = true
        else
          success.push(entry.entry_id)

          temp_row = table.row(entry.row_id)
          temp_row.data().status = entry.status
          temp_row.data().resolution = entry.resolution
          temp_row.data().internal_comment = entry.comment
          temp_row.data().resolution_comment = entry.resolution_comment
          temp_row.data().category = entry.category_names
          temp_row.data().category_names = entry.category_names
          temp_row.invalidate().page(table_page).draw(false)
          temp_row.child().remove()
          temp_row.child(format(temp_row)).show()
          nested_tooltip()
          $('#input_cat_'+ entry.entry_id).selectize {
            persist: false,
            create: false,
            maxItems: 5,
            closeAfterSelect: true,
            valueField: 'category_id',
            labelField: 'category_name',
            searchField: ['category_name', 'category_code'],
            options: AC.WebCat.createSelectOptions('#input_cat_'+ entry.entry_id)
            items: selected_options(entry.categories)
          }
          $('#input_cat_pending'+ entry.entry_id).selectize {
            persist: false,
            create: false,
            maxItems: 5,
            closeAfterSelect: true,
            valueField: 'category_id',
            labelField: 'category_name',
            searchField: ['category_name', 'category_code'],
            options: AC.WebCat.createSelectOptions('#input_cat_pending'+ entry.entry_id)
            items: selected_options(entry.categories)
          }

      success_boiler_plate = "The following entries were successfully saved: " + success.toString() + "<br>"
      api_boiler_plate =  "The following entries could not be saved due to API errors: " + api_errors.toString() + "<br>"
      no_cats_boiler_plate = "The following entries could not be saved (no categories): " + nil_categories_errors.toString()

      error_msg = ''

      if success.length > 0
        error_msg += success_boiler_plate
      if api_errors.length > 0
        error_msg += api_boiler_plate

      if nil_categories_errors.length > 0
        error_msg += no_cats_boiler_plate

      if errors == true
        std_msg_error(error_msg,"")
      else
        std_msg_success('Success',["All complaints successfully processed."], reload: true)

      tds = $('#complaints-index tbody').closest('td')
      for td in tds
        if td.className == ''
          td.classList.add('nested-complaint-data-wrapper')

      $('#master-submit').prop('disabled', false)
    error: (response) ->
      std_msg_error("Unable to submit changes for selected entries.","", reload: false)
      $('#master-submit').prop('disabled', false)

  , this)

window.master_submit = () ->
  selectedItems = $('.selected + tr td.nested-complaint-data-wrapper')
  thingsSelected = getTouchedFormCount()
  if thingsSelected > selectedItems.length
    std_msg_confirm(
      "Changes have been made to at least " + thingsSelected +  " complaints but only " + selectedItems.length + " items are selected.", ["Updating selected items will reload the page and other changes will be lost."],
      {
        reload: false,
        confirm_dismiss: true,
        confirm: ->
          processSubmitMaster()
      })
  else
    processSubmitMaster()


# Checks if there have been changes on the page
# Enables the bulk submit button if there have been
window.verifyMasterSubmit = () ->
  changes = getTouchedFormCount()
  boolean = false
  if $(changes).length > 0
    boolean = true
  return boolean



window.updateResolutionDialog = (confirm) ->
#   { status } = row
#  if status == 'COMPLETED'
#    reopened = true
#    disabled = false
#  if  status == 'RESOLVED' || status == 'NEW' || status == 'ASSIGNED'|| status == 'REOPENED'
#    invalid_unchanged = true
#    disabled = false
  $('#complaint_entries_to_update').empty()
  resolution = $('#complaint_resolution')[0].value
  selected_rows = $('tr.selected')
  pending_msg = ''
  complaint_entries = []
  for row in selected_rows
    { id } = row
    status = $(row).find('.state-col').text()
    if status == 'PENDING'
      if pending_msg == ''
        pending_msg = "<div class='small pending-note'>*Entries with a PENDING status cannot be edited.<div>"
    else
      push_row = false
      if resolution == 'REOPENED' && status == 'COMPLETED'
        push_row = true

      if resolution == 'RESOLVED' || status == 'NEW' || status == 'ASSIGNED'|| status == 'REOPENED'
        if resolution == 'INVALID' || resolution == 'UNCHANGED'
          push_row = true

      if push_row
        $(row).addClass('filtered-row')
        complaint_entries.push(id)
        full_domain = ''
        domain = $(row).find("#domain_#{id}").attr('data-full')
        $('#complaint_entries_to_update').append("<tr><td><span class='res_id'>#{id} |</span> <span class='webcat-full-domain'>#{domain}</span></td></tr>")
  $('#resolution_dialog').modal("show")
  if selected_rows.length > 1
    html = "Set the following #{complaint_entries.length} entries to <span class='bold'>RESOLUTION</span> <span class='resolution-emp bold'>#{resolution}.</span>"
  else
    html = "Set the following entry to <span class='bold'>RESOLUTION</span> <span class='resolution-emp bold'>#{resolution}.</span>"
  html += pending_msg
  $('#resolution_text').html(html)

  tbody = $('#resolution_dialog').find('tbody')
  setTimeout ->
    if $('#complaint_entries_to_update').height() > 399
      $(tbody).addClass('scrollable-table')
      $('#resolution_text').css('padding-left', 0)
    else
      $('#resolution_text').css('padding-left', '7px')
  , 200

window.updateResolution = () ->
  resolution = $('#complaint_resolution')[0].value
  selected_rows = $('tr.selected.filtered-row')
  internal_comment = $('#internal_comment')[0].value
  customer_facing_comment = $('#customer_facing_comment')[0].value

  complaint_entries = []
  for row in selected_rows
    status = $(row).find('.state-col').text()
    if status != 'PENDING'
      complaint_entries.push(row.id)

  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/webcat/complaint_entries/update_resolution"
    data: {'complaint_entries': complaint_entries, 'resolution': resolution, 'internal_comment': internal_comment, 'customer_facing_comment': customer_facing_comment}
    success_reload: true
    success: (response) ->
      $('#resolution_dialog').modal('hide')
      data = JSON.parse(response)
      resolution = data[0].resolution
      modal_message = ""
      error = []
      success = []
      for entry in data
        { host, status, state} = entry
        if state == "ERROR"
          error_msg = "<li><span class='resolution-error-host'>#{host}</span> Cannot change entry with status of <span class='resolution-emp bold'>#{status}</span> to <span class='resolution-emp bold'>#{resolution}</span></li>"
          error.push(error_msg)
        else
          success.push(host)

      if success.length
        modal_message = "<div class='resolution-message'>Successfully updated <span class='bold'>RESOLUTION</span> to <span class='resolution-emp bold'>#{resolution}</span> for #{success.length} Complaint Entries</div>"
        if !error.length
          std_msg_success("All entries were successfully updated.", [modal_message], reload: true)
      if error.length
        error_list = error.join('')

        modal_message += "<div class='resolution-message'>Error updating the  following #{error.length} Complaint Entries:</div> <ul class='update-resolution-entries'>#{error_list}</ul>"
        std_msg_error("Error updating resolutions.", [modal_message], reload: true)
        setTimeout ->
          if $('.update-resolution-entries').height() > 300
            $('.update-resolution-entries').addClass('scrollable-list')
        ,200
      # Determine whether to render a success or error modal accordingly

  )

$ ->



      #Call new function, fix this
  $(document).on 'change', '.resolution_radio_button', ->
    debugger
    id = this.name.split("resolution")[1]
    domain = $("#complaint_prefix_"+id)[0].dataset.domain
    store_entry_changes(domain)
    $('#master-submit').prop('disabled', false)



  $('#complaints_check_box, #complaints_select_all').click ->
    checked = $(this).prop('checked')

    if checked
      $('#complaints-index').DataTable().rows( { page: 'current' } ).select()
    else
      $('#complaints-index').DataTable().rows().deselect()

    $("#complaints_check_box").prop('checked', checked)
    $("#complaints_select_all").prop('checked', checked)
    return

  $(document).ready ->
    if !window.location.pathname.includes('/escalations/webcat')
      $('#filter-complaints-nav').hide()
      $('#fetch').hide()
      $('#complaints-nav-search-wrapper').hide()
      $('#new-complaint-nav-wrapper').hide()
    else
      $('#filter-complaints').show()
      $('#fetch').show()
      $('#complaints-nav-search-wrapper').show()
      $('#new-complaint-nav-wrapper').show()

  # If a stupidly long email address is returned it will wrap
  # rather than pushing the column into the column beside it
  $('.email-row').find('.case-history-author').each ->
    if $(this).text().length > 28
      $(this).addClass('break-word')






