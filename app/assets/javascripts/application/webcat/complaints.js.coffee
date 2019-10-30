table_page = 0

$(document).on 'click', '.paginate_button', ->
  complaint_table = $('#complaints-index').DataTable().context
  if complaint_table.length > 0
    table = $('#complaints-index').DataTable()
    table_page = table.page.info().page



#### WBNP Reporting ####
$(document).ready ->
  if ($('body').hasClass('escalations--webcat--complaints-controller') || $('body').hasClass('escalations--webcat--reports-controller')) &&
     $('body').hasClass('index-action')
    window.check_wbnp_status()


# WBNP - Get report id
window.fetch_wbnp_data = () ->
  $('#fetch_wbnp').attr('disabled', true)
  $('#fetch_wbnp').addClass('esc-tooltipped')
  $('.wbnp-loading-spinner').show()
  std_msg_ajax(
    method: 'POST'
    url: '/escalations/api/v1/escalations/webcat/complaints/fetch_wbnp_data'
    data: {}
    success: (response) ->
      json = $.parseJSON(response)
      wbnp_report_id = json.wbnp_report_id
      check_wbnp_status(wbnp_report_id)

    error: (response) ->
      std_api_error(response, 'Error fetching wbnp data complaints.', reload: false)
  )


# WBNP - Check report info
check_wbnp = window.check_wbnp_status = (wbnp_report_id) ->
  # Turn on loader indicator
  $('.wbnp-loading-spinner').show()

  # Set status on header to checking
  top_status = $('.top-area-bar').find('.wbnp-report-status')[0]
  $(top_status).text('Checking...')

  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/webcat/complaints/wbnp_report_status"
    data: {wbnp_report_id: wbnp_report_id }
    success: (response) ->
      total_new_cases = response.data.total_new_cases
      cases_imported = response.data.cases_imported
      cases_failed = response.data.cases_failed
      status = response.data.status

      # Turn of loader indicator
      $('.wbnp-loading-spinner').hide()

      # Add fields to table & header
      $('.wbnp-report-status').text(status)
      $('#wbnp-report-attempted').text(total_new_cases)
      $('#wbnp-report-succeeded').text(cases_imported)
      $('#wbnp-report-rejected').text(cases_failed)

      # If status is active, fetch button should be disabled
      if status == 'active'
        $('#fetch_wbnp').attr('disabled', true)
        $('#fetch_wbnp').removeClass('esc-tooltipped')
        # Check in 5 minutes to see if report has finished
        setTimeout(check_wbnp, 120000)
      else
        $('#fetch_wbnp').attr('disabled', false)
        $('#fetch_wbnp').addClass('esc-tooltipped')

    error: (response) ->
      $('.wbnp-loading-spinner').hide()
      std_msg_error("Unable to pull wbnp status", [], reload: false)
  )



window.updateURI = (event, complaint_entry_id) ->
  event.preventDefault()

  $('#loader-modal').modal({
    keyboard: false
  })

  uri = $("#complaint_prefix_#{complaint_entry_id}").val()

  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/webcat/complaints/update_uri"
    data: {complaint_entry_id: complaint_entry_id, uri: uri }
    success: (response) ->
      {current_categories, category, wbrs_score, domain, subdomain, path, status} = response.json

      $('#loader-modal').modal 'hide'

      $(".simple-nested-table#entry-table-#{complaint_entry_id} tbody > tr").remove()

      if 'ip' == status
        std_msg_error("Cannot edit IP entries.","")
      else
        $.each current_categories, (key, entry) ->
          $(".simple-nested-table#entry-table-#{complaint_entry_id}").append("<tr><td>#{entry.confidence}</td><td>#{entry.mnem} - #{entry.descr}</td><td>#{entry.top_certainty}</span></td></tr>")

        $("#domain_#{complaint_entry_id}").text(domain)
        $("#subdomain_#{complaint_entry_id}").text(subdomain)
        $("#path_#{complaint_entry_id}").text(path)
        $("#category_#{complaint_entry_id}").text(category)
        $("#wbrs_score_#{complaint_entry_id}").text(wbrs_score)

        $("#entry-uri-#{complaint_entry_id}").html("<a href='http://#{uri}' target='_blank' onclick='select_cat_text_field(#{complaint_entry_id})' >#{uri}</a>")
        $("#site-search-#{complaint_entry_id}").html("<a href='https://www.google.com/search?q=site%3A#{uri}' target='_blank' onclick='select_cat_text_field(#{complaint_entry_id})'>#{uri}</a>")

        $("#lookup-#{complaint_entry_id}").replaceWith('<button class="secondary" id="lookup-' + complaint_entry_id + '" onclick="WebCat.RepLookup.queryWhoIs(\'' + domain + '\')">Lookup</button>')
        $("#history-#{complaint_entry_id}").replaceWith('<button class="secondary" id="history-' + complaint_entry_id + '" onclick="history_dialog(' + complaint_entry_id + ',\'' + uri + '\')">History</button>')
        $("#domain-#{complaint_entry_id}").replaceWith('<button class="secondary" id="domain-' + complaint_entry_id + '" onclick="domain_whois(\''+domain+'\')">Domain</button>')
    error: (response) ->
      $('#loader-modal').modal 'hide'
      std_msg_error("Unable to update URI", [response.responseJSON.message], reload: false)

 )

window.cat_new_url = ()->

  data = {}
  isEmpty = true

  for i in [1...6] by 1

    data[i] = {url: $("#url_#{i}").val(), cats: $("#cat_new_url_#{i}").val()}

    if data[i].url.length > 0 && data[i].cats != null
      isEmpty = false

  if isEmpty == false

    $('#loader-modal').modal({
      keyboard: false
    })

    std_msg_ajax(
      url:'/escalations/api/v1/escalations/webcat/complaints/cat_new_url'
      method: 'POST'
      data: {data: data}
      success: (response) ->
        $('#loader-modal').modal 'hide'
        std_msg_success('URLs categorized successfully',["Categorization of a Top URL will create a pending complaint entry.", "All other entries have been submitted directly to WBRS."], reload: true)

      error: (response) ->
        $('#loader-modal').modal 'hide'
        if response.responseText.includes('Either no products have been defined to enter bugs against or you have not been given access to any.')
          std_api_error(response, "Please make sure you have the appropriate permissions in Bugzilla. Unable to categorize url.", reload: false)
        else
          std_api_error(response, "Unable to categorize url.", reload: false)
    )
  else
    std_msg_error("Unable to categorize", ["Please confirm that a URL and at least one category for each desired entry exists."], reload: false)


window.webcat_reset_search = ()->
  inputs = document.getElementsByClassName('form-control')
  for i in inputs
    i.value = ""
  tags_select = $('#tags-input').selectize()
  tags_control = tags_select[0].selectize
  tags_control.clear()

window.multiple_url_categorization = ()->

  urls = $("#categorize_urls").val().split(/\n/)
  cats = $("#multi_cat_url_cats").val()

  if $("#categorize_urls").val() != "" && cats != null
    $('#loader-modal').modal({
      keyboard: false
    })

    std_msg_ajax(
      url:'/escalations/api/v1/escalations/webcat/complaints/multi_cat_new_url'
      method: 'POST'
      data: {urls: urls, cats: cats}
      success: (response) ->
        $('#loader-modal').modal 'hide'
        std_msg_success('Success',["URLs/IPs successfully categorized."], reload: true)
      error: (response) ->
        $('#loader-modal').modal 'hide'
        std_msg_error('Error' + ' ' + response.responseJSON.message,"", reload: false)
    )
  else
    $('#loader-modal').modal 'hide'
    std_msg_error('Error', ['Please check that a URL/IP has been inputted and that at least one category was selected.'], reload: false)


window.inheritCategories = (complaint_entry_id) ->
  std_msg_ajax(
    url:'/escalations/api/v1/escalations/webcat/complaint_entries/inherit_categories_from_master_domain'
    method: 'POST'
    data: {'id': complaint_entry_id}
    success: (response) ->
      $('#loader-modal').modal 'hide'
      $('.domain-categories').hide()
      std_msg_success('Success',["Successfully inherited categories from main domain."], reload: false)

    error: (response) ->
      $('#loader-modal').modal 'hide'
      std_msg_error('Error' + ' ' + response.responseJSON.message,"", reload: false)
    )

name_servers =(server_list)->
  if undefined == server_list
    ''
  else
    i = 0
    text = ""
    while i < server_list.length
      text += server_list[i] + '<br>'
      i++
    text

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

window.updatePending = (id,row_id) ->
  prefix = $('#complaint_prefix_'+id)[0].value
  status = $('[name=resolution_review_'+id+']:checked').val()
  comment = $('#complaint_comment_'+id)[0].value
  resolution_comment = $('#complaint_resolution_comment_'+id)[0].value
  resolution = $('.complaint-resolution'+id).text()
  #get the selectize control for the category input
  selectizeControl = $('#input_cat_'+id).selectize()[0].selectize
  if $('#input_cat_'+id).val() == null
    categories = null
  else
    categories = $('#input_cat_'+id).val().toString()

  named_categories = ""
  i = 0
  if categories == null
    cat_array = []
  else
    cat_array = categories.split(',')
    while i < cat_array.length
      named_categories = named_categories + selectizeControl.getItem(cat_array[i]).text()
      i++
      if i < cat_array.length
        named_categories += ", "

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/update_pending'
    method: 'POST'
    data: {'id': id,'prefix': prefix,'commit':status,'status':resolution,'comment':comment, 'resolution_comment': resolution_comment, 'categories': categories, 'category_names':named_categories }
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

        $('#input_cat_'+ temp_row.data().entry_id).selectize {
          persist: false,
          create: false,
          maxItems: 5,
          valueField: 'category_id',
          labelField: 'category_name',
          searchField: ['category_name', 'category_code'],
          options: AC.WebCat.createSelectOptions(),
          items: selected_options(temp_row.data().category)
        }

        $("#domain_#{entry_id}").text(domain)
        $("#subdomain_#{entry_id}").text(subdomain)
        $("#path_#{entry_id}").text(path)

      tds = $('#complaints-index tbody').closest('td')
      for td in tds
        if td.className == ''
          td.classList.add('nested-complaint-data-wrapper')
    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)


## Called when user submits categories / information to close a ticket
window.updateEntryColumns = (entry_id,row_id) ->
  $("#submit_changes_#{entry_id}").addClass('hidden')
  $("#reopen_#{entry_id}").removeClass('hidden')

  prefix = $('#complaint_prefix_'+entry_id)[0].value
  if $('#input_cat_'+entry_id).val() != null
    categories = $('#input_cat_'+entry_id).val().toString()
  else
    categories = null
  category_name = $('#input_cat_' + entry_id).next('.selectize-control').find('.item')
  category_names = []
  category_name.each ->
    category_names.push($(this).text())
  category_names = category_names.toString()
  resolution_status = $('[name=resolution'+entry_id+']:checked').val()
  comment = $('#complaint_comment_'+entry_id)[0].value
  resolution_comment = $('#complaint_resolution_comment_'+entry_id)[0].value
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  fixed_flag = $('#fixed'+entry_id).is(':checked')

  # If resolution is set to fixed, make sure it has categories applied
  if categories == null && fixed_flag == true
    std_msg_error("Must include at least one category.","", reload: false)
    $("#submit_changes_#{entry_id}").removeClass('hidden')
    $("#reopen_#{entry_id}").addClass('hidden')
  else
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/update'
      method: 'POST'
      headers: headers
      data: {'id': entry_id, 'prefix': prefix, 'categories':categories, 'category_names':category_names, 'status':resolution_status, 'comment':comment, 'resolution_comment': resolution_comment }
      success: (response) ->
        {categories, error, uri, domain, subdomain, path, status, display_name} = $.parseJSON(response)

        if !error
          table = $('#complaints-index').DataTable()

          selected_rows = $('#complaints-index').DataTable().rows('.selected')
          selected_rows.data().cell(selected_rows[0][0],14).data("#{display_name}").draw()

          temp_row = table.row(row_id)
          temp_row.data().status = status
          temp_row.data().resolution = resolution_status
          temp_row.data().internal_comment = comment
          temp_row.data().resolution_comment = resolution_comment
          temp_row.data().category = category_names
          temp_row.data().category_names = category_names
          temp_row.invalidate().page(table_page).draw(false)
          temp_row.child().remove()
          temp_row.child(format(temp_row)).show()

          $('#input_cat_'+ temp_row.data().entry_id).selectize {
            persist: false,
            create: false,
            maxItems: 5
            valueField: 'category_id',
            labelField: 'category_name',
            searchField: ['category_name', 'category_code'],
            options: AC.WebCat.createSelectOptions()
            items: selected_options(categories)
          }
  
          $('#input_cat_pending'+ temp_row.data().entry_id).selectize {
            persist: false,
            create: false,
            maxItems: 5
            valueField: 'category_id',
            labelField: 'category_name',
            searchField: ['category_name', 'category_code'],
            options: AC.WebCat.createSelectOptions()
            items: selected_options(categories)
          }
          unless status == 'COMPLETED'
            $('#input_cat_'+ temp_row.data().entry_id).selectize {
              persist: false,
              create: false,
              maxItems: 5
              valueField: 'category_id',
              labelField: 'category_name',
              searchField: ['category_name', 'category_code'],
              options: AC.WebCat.createSelectOptions()
              items: selected_options(temp_row.data().category_names)
            }
          else
            # For entries that are 'Completed', we need to initialize the selectize function
            # and then disable it
            $completed_selectize = $('#input_cat_'+ temp_row.data().entry_id).selectize {
              persist: false,
              create: false,
              maxItems: 5
              valueField: 'category_id',
              labelField: 'category_name',
              searchField: ['category_name', 'category_code'],
              options: AC.WebCat.createSelectOptions()
              items: selected_options(temp_row.data().category_names)
            }
            select_complete = $completed_selectize[0].selectize
            select_complete.disable()

          $("#complaint_prefix_#{entry_id}").val(uri)
          $("#domain_#{entry_id}").text(domain)
          $("#subdomain_#{entry_id}").text(subdomain)
          $("#path_#{entry_id}").text(path)
          $("#entry-uri-#{entry_id}").html("<a href='http://#{uri}' target='_blank' onclick='select_cat_text_field(#{entry_id})' >#{uri}</a>")
          $("#site-search-#{entry_id}").html("<a href='https://www.google.com/search?q=site%3A#{uri}' target='_blank' onclick='select_cat_text_field(#{entry_id})'>#{uri}</a>")

        tds = $('#complaints-index tbody').closest('td')
        for td in tds
          if td.className == ''
            td.classList.add('nested-complaint-data-wrapper')

      error: (response) ->
        $("#submit_changes_#{entry_id}").removeClass('hidden')
        $("#reopen_#{entry_id}").addClass('hidden')
        std_msg_error(response,"", reload: false)
    , this)


## Allows analyst to set ticket status to reopened and allows them to interact with the submission form
window.reopenComplaint = (entry_id, button) ->
  $('#loader-modal').modal({
    keyboard: false
  })
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
      $('#loader-modal').modal 'hide'
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
          std_msg_error('take error', json.error)
        else
          i = 0
          while i < selected_rows[0].length
            selected_rows.data().cell(selected_rows[0][i],14).data(json.name).draw()
            selected_rows.data().cell(selected_rows[0][i],4).data("ASSIGNED").draw()
            i++

      error: (response) ->
        notice_html = "<p>Something went wrong: #{response.responseText}</p>"
    , this)
  else
    std_msg_error('No rows selected', ['Please select at least one row.'])



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
          std_msg_error('return error', json.error)
        else
          i = 0
          while i < selected_rows[0].length
            selected_rows.data().cell(selected_rows[0][i],14).data("Vrt Incoming").draw()
            selected_rows.data().cell(selected_rows[0][i],4).data("NEW").draw()
            i++

      error: (response) ->
        notice_html = "<p>Something went wrong: #{response.responseText}</p>"
    , this)
  else
    std_msg_error('no rows selected', ['Please select at least one row.'])

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

selected_options = (category_names) ->

  options = []
  if category_names
    options = category_names.split(',')
  return options

$('html').on 'click', (e) ->
  if typeof $(e.target).data('original-title') == 'undefined' and !$(e.target).parents().is('.popover.in')
    $('[data-original-title]').popover 'hide'


$(document).on 'click', ".popover .screenshot-retake-button", ->
  $('[data-original-title]').popover 'hide'
  se_id = this.id.slice(6)
  std_msg_ajax(
    method: 'GET'
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/' + se_id + '/retake_screenshot'
    data: {}
    error_prefix: 'Error retaking screenshot.'
    success: (response) ->
      std_msg_success('Screenshot job initiated. Check back in about 10 seconds.', [], reload: true)
  )

$(document).on 'click', ".popover .screenshot-reload-button", ->
  location.reload(true)

$(document).on 'click', ".screenshot-close-button", ->
  $('.webcat-screenshot').hide()

window.enlarge_image = (id,image,retake_in_progress)->
  image_content = ""
  if retake_in_progress
    image_content = '<img src="' + image + '"><span class="screenshot-button screenshot-reload-button esc-tooltipped" title="Reload Page">Reload Page</span>'
  else
    image_content = '<img src="' + image + '"><span class="screenshot-button screenshot-retake-button esc-tooltipped" id="se_id_' + id + '" title="Retake Screenshot"></span><span class="screenshot-button screenshot-close-button"></span>'

  $('#screenshot_id_'+ id).popover(
    html: true
    container: 'body'
    trigger: 'focus'
    template: '<div class="popover webcat-screenshot"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>'
    content: image_content).popover 'show'

window.lookup_prefix = () ->

  $('#loader-modal').modal({
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
          for [j .. Object.keys(response.json[i]).length]
            selector = '#cat_new_url_' + i.toString()
            $select= $(selector).selectize()
            selectize = $select[0].selectize
            selectize.addItem(response.json[i][j])
            j++
        catch
          i++
          continue
        i++
      $('#loader-modal').modal 'hide'
  )

window.retrieve_history = (position) ->
  $(".cat-url-error").hide()

  for url_position in [1..5]
    $("#url_#{url_position}").css("border-width", "")
    $("#url_#{url_position}").css("border-color", "")

  url = $("#url_" + position).val()

  if url.length > 0

    $('#loader-modal').modal({
      keyboard: false
    })

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/categorize_urls_history'
      method: 'POST'
      data: {'position': position, url: url}
      success: (response) ->
        $('#loader-modal').modal 'hide'

        json = JSON.parse(response)
        if json.error
          std_msg_error("<p>Something went wrong: #{json.error}","")
        else
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

          if $("#history_dialog").length
            history_dialog = this
            $("#history_dialog").html(history_dialog_content)
            $('#history_dialog').dialog('open')
          else
            history_dialog = '<div id="history_dialog" title="History Information"></div>'
            $('body').append(history_dialog)
            $("#history_dialog").html(history_dialog_content)
            $('#history_dialog').dialog
              autoOpen: false
              minWidth: 600
              position: { my: "right top", at: "right top", of: window }
            $('#history_dialog').dialog('open')

      error: (response) ->
        $("#cat-url-error-message-#{position}").text("No history associated with this url.")
        $('#loader-modal').modal 'hide'
        $("#cat-url-#{position}").show()
        $("#url_#{position}").css("border-width", "2px")
        $("#url_#{position}").css("border-color", "#E47433")

    , this)
  else
    $("#cat-url-error-message-#{position}").text("No data available for blank URL.")
    $("#cat-url-#{position}").show()
    $("#url_#{position}").css("border-width", "2px")
    $("#url_#{position}").css("border-color", "#E47433")


window.drop_current_categories = () ->
  $(".cat-url-error").hide()
  $(".cat-url-success").hide()

  $('#loader-modal').modal({
    keyboard: false,
  })

  $("#url_#{i}").css("border-width", "")
  $("#url_#{i}").css("border-color", "")

  urls = {}

  for i in [1 .. 5]
    if $("#url_" + i ).val() != ""
      urls[i] = $("#url_" + i ).val()

  std_msg_ajax(
    url:'/escalations/api/v1/escalations/webcat/complaints/drop_current_categories'
    method: 'POST'
    data: { 'urls': urls }
    success: (response) ->
      for key, value of response.json
        if value && value.code == 200
          $("#cat-url-success-message-#{key}").text("Categories successfully dropped.")
          $("#cat-url-success-#{key}").show()
          select= $("#cat_new_url_#{key}").selectize()
          selectize = select[0].selectize
          selectize.clear()
        else
          $("#url_#{key}").css("border-width", "2px")
          $("#url_#{key}").css("border-color", "#E47433")
          $("#cat-url-error-message-#{key}").text("Unable to drop categories.")
          $("#cat-url-#{key}").show()
      $('#loader-modal').modal 'hide'
    error: (response) ->
      std_msg_error("<p>There has been an error dropping categories: #{json.error}","")
)

format = (complaint_entry_row) ->
  $('#loader-modal').modal({
    keyboard: false,
  })


  complaint_entry = complaint_entry_row.data()
  row_id = complaint_entry_row[0][0]
  missing_data = '<span class="missing-data">No Data</span>'
  uri = ''
  host = ''
  url = ''
  search_uri = ''
  if complaint_entry.uri
    host = complaint_entry.uri
    url = host
    uri = '<a href="http://' + complaint_entry.uri + '"  target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + complaint_entry.uri + '</a>'
    search_uri = '<a href="https://www.google.com/search?q=site%3A' + complaint_entry.uri + '" target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + complaint_entry.uri + '</a>'
  else if complaint_entry.domain
    if complaint_entry.subdomain
      host = complaint_entry.subdomain + '.'
    host = host + complaint_entry.domain
    url = host
    if complaint_entry.path
      url = host
    uri = '<a href="http://' + url + '" target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + url + '</a>'
    search_uri = '<a href="https://www.google.com/search?q=site%3A' + url + '" target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + url + '</a>'
  else if  complaint_entry.ip_address
    host = complaint_entry.ip_address
    url = host
    uri = '<a href="http://' + complaint_entry.ip_address + '"  target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + complaint_entry.ip_address + '</a>'
    search_uri = '<a href="https://www.google.com/search?q=site%3A' + complaint_entry.ip_address + '" target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + complaint_entry.ip_address + '</a>'
  else
    uri = missing_data

  entry_status = ""
  reopen_class = "hidden"
  submit_class = ""
  status_class = ""
  # Disabling all interactive elements if entry is 'Completed'
  if complaint_entry.status == "COMPLETED"
    entry_status = "disabled='true'"
    reopen_class = ""
    submit_class = "hidden"
    status_class = "completed"
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

  customer_name = ''
  if complaint_entry.customer_name
    customer_name = complaint_entry.customer_name
  else
    customer_name = missing_data

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

  category_row = ''
  tooltip_table = ''
  tooltip_all = ''
  tooltip_wrapper_start = '<div class="tooltip_templates"><span id="'
  tooltip_table_start = '<table class="category-tooltip-table"><thead><tr><th>Certainty</th><th>Source</th><th>Description</th></tr></thead><tbody>'
  tooltip_table_guts = ''
  tooltip_table_end = '</tbody></table>'
  tooltip_wrapper_end = '</span></div>'


  std_msg_ajax(
    method: 'POST'
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/retrieve_current_categories'
    data: {'id': complaint_entry.entry_id}
    success: (response) ->
      $('#loader-modal').modal 'hide'
    
      { current_category_data : current_categories, master_categories, sds_category} = JSON.parse(response)

      sds_category == '' unless sds_category != null

      master_categories_list = '#main-domain-categories_' + complaint_entry.entry_id

      if master_categories && master_categories.length > 0
        $(master_categories_list).closest('.domain-categories').show()
        for cat in master_categories
          new_cat = '<li>' + cat + '</li>'
          $(master_categories_list).append(new_cat)

      $.each current_categories, (key, value) ->
        active =  $(this).attr("is_active")
        if active == true
          { confidence, mnem: mnemonic, descr: name, category_id: cat_id, top_certainty, certainties } = this

          $(certainties).each ->
            { certainty:source_certainty, source_description, source_mnemonic: source_name } = this
            certainty_row = '<tr><td>' + source_certainty + '</td><td>' + source_name + '</td><td>' + source_description + '</td></tr>'
            tooltip_table_guts = tooltip_table_guts + certainty_row

          tooltip_table = tooltip_table_start + tooltip_table_guts + tooltip_table_end
          tooltip_all = tooltip_wrapper_start + 'certainty_table' + complaint_entry.entry_id + '_' + cat_id + '">' + tooltip_table + tooltip_wrapper_end

          if key == '1.0'
            category_row = '<tr><td>' + confidence + '</td><td>' + mnemonic + ' - ' + name + '</td><td><span class="certainty-flag nested-tooltipped" onmouseover="triggerTooltips(this)" data-tooltip-content="#certainty_table' + complaint_entry.entry_id + '_' + cat_id + '">' + top_certainty + '</span>' + tooltip_all + '</td><td class=sds_category>' + sds_category + '</td></tr>'
            $(".simple-nested-table" + "#entry-table-" + complaint_entry.entry_id).append(category_row)
          else
            category_row = '<tr><td>' + confidence + '</td><td>' + mnemonic + ' - ' + name + '</td><td><span class="certainty-flag nested-tooltipped" onmouseover="triggerTooltips(this)" data-tooltip-content="#certainty_table' + complaint_entry.entry_id + '_' + cat_id + '">' + top_certainty + '</span>' + tooltip_all + '</td></tr>'
            $(".simple-nested-table" + "#entry-table-" + complaint_entry.entry_id).append(category_row)

      if jQuery.isEmptyObject(current_categories) == true && sds_category
        category_row = '<tr><td><td></td><td></td><td class=sds_category>' + sds_category + '</td></tr>'
        $(".simple-nested-table" + "#entry-table-" + complaint_entry.entry_id).append(category_row)

    error: (response) ->
      $('#loader-modal').modal 'hide'
      current_categories = ''
  )

  if complaint_entry.entry_history?
    if complaint_entry.entry_history.complaint_history.length >= 1
      complaint_history = complaint_entry.entry_history.complaint_history
    else
      complaint_history = ''

  whois_lookup = if complaint_entry.ip_address then complaint_entry.ip_address else complaint_entry.domain


  complaint_entry_html = ''
  input_cat = 'input_cat_' + complaint_entry.entry_id

  if complaint_entry.status == "PENDING"
    complaint_table_row_html = '<table class="active_table"><tr class="pending"><td class="no_pad"><div class="row">'
    complaint_submission_html =
        '<input type="radio" name="resolution_review_' + complaint_entry.entry_id + '" value="commit" > Commit <br/>' +
        '<input type="radio" name="resolution_review_' + complaint_entry.entry_id + '" value="decline" checked="checked"> Decline' +
        '<br/>' +
        '<button class="tertiary" onclick="updatePending(' + complaint_entry.entry_id + ',' + row_id + ')"> Submit </button>' +
        '</div>'
  else
    complaint_table_row_html = '<table class="active_table"><tr class="active_master_submit" type="submit_changes" entry_id="' + complaint_entry.entry_id + '"  row_id = "' + row_id + '"><td class="no_pad"><div class="row">'
    complaint_submission_html =
        '<input type="radio" class="resolution_radio_button" id="unchanged' + complaint_entry.entry_id + '" name="resolution' + complaint_entry.entry_id + '" value="UNCHANGED" ' + unchanged_radio + entry_status + '> Unchanged <br/> ' +
        '<input type="radio" class="resolution_radio_button" id="fixed' + complaint_entry.entry_id + '" name="resolution' + complaint_entry.entry_id + '" value="FIXED"  ' + fixed_radio + entry_status + '> Fixed  <br/> ' +
        '<input type="radio" class="resolution_radio_button" id="invalid' + complaint_entry.entry_id + '" name="resolution' + complaint_entry.entry_id + '" value="INVALID" ' + invalid_radio + entry_status + '> Invalid' +
        '<br/>' +
        '<button class="tertiary submit_changes ' + submit_class + '" id="submit_changes_' + complaint_entry.entry_id + '" onclick="updateEntryColumns(' + complaint_entry.entry_id + ',' + row_id + ')">Submit Changes</button>' +
        '<button class="tertiary ' + reopen_class + '" id="reopen_' + complaint_entry.entry_id + '" onclick="reopenComplaint(' + complaint_entry.entry_id + ', this)">Reopen Complaint</button>' +
        '</div>'

  retake_in_progress = false
  if complaint_entry.screen_shot_error == "Retaking screenshot please wait."
    retake_in_progress = true

  complaint_entry_html =
      complaint_table_row_html +
      '<div class="col-xs-12 col-sm-8 nested-complaint-static-data">' +
      '<div class="row">' +
      '<div class="col-xs-3 col-with-divider">' +
      '<div class="screenshot-thumb-wrapper">' +
      '<img id="screenshot_id_' + complaint_entry.entry_id + '" class="screenshot-thumb-img" title="' + screen_shot_error + '" data-toggle="popover" onclick="enlarge_image(' + complaint_entry.entry_id + ',\'complaint_entries/serve_image?complaint_entry_id=' + complaint_entry.entry_id + '\',' + retake_in_progress + '\)" src="complaint_entries/serve_image?complaint_entry_id=' + complaint_entry.entry_id + '" />' +
      '</div>' +
      '<div class="complaint-entry-info">' +
      '<label class="content-label-sm">Case ID</label>' +
      '<span class="nested-complaint-data case-id"><a href="complaints/' + complaint_entry.complaint_id + '">' + complaint_entry.complaint_id + '</a></span>' +
      '<label class="content-label-sm">Entry URI</label>' +
      '<span class="nested-complaint-data input-truncate esc-tooltipped" id="entry-uri-' + complaint_entry.entry_id + '" title="' + url + '">' + uri + '</span>' +
      '<label class="content-label-sm" id="site-search">Site Search</label>' +
      '<span class="nested-complaint-data input-truncate esc-tooltipped" id="site-search-' + complaint_entry.entry_id + '" title="' + url + '">' + search_uri + '</span>' +
      '<label class="content-label-sm">Customer Name</label>' +
      '<span class="nested-complaint-data">' + customer_name + '</span>' +
      '<label class="content-label-sm">Customer Description</label>' +
      '<span class="nested-complaint-data">' + customer_description + '</span>' +
      '</div></div><div class="col-xs-7 col-with-divider">' +
      '<table class="simple-nested-table" id="entry-table-' + complaint_entry.entry_id + '"><thead><tr><th class="col-sm-1">Conf</th><th class="col-sm-4">WBRS Categories</th><th class="col-sm-3">WBRS Certainty</th><th class="col-sm-4">SDS Category</tr></thead>' +
      '</table>' +
      '</br>' +
      '</div><div class="col-xs-2">' +
      '<button class="secondary" id="lookup-' + complaint_entry.entry_id + '" onclick="WebCat.RepLookup.queryWhoIs(\'' + url + '\')">Lookup</button><br/>' +
      '<button class="secondary" id="history-' + complaint_entry.entry_id + '" onclick="history_dialog(' + complaint_entry.entry_id  + ',\'' + url + '\')">History</button><br/>' +
      '<button class="secondary" id="domain-' + complaint_entry.entry_id + '" onclick="domain_whois(\'' + whois_lookup + '\')">Domain</domain>' +
      '</div></div>' +
      '</div><div class="col-xs-12 col-sm-4 nested-complaint-editable-data">' +
      '<div class="row">' +
      '<div class="col-xs-12">' +
      '<label class="content-label-sm">Edit URI</label><br/>' +
      '<input class="nested-table-input complaint-uri-input" id="complaint_prefix_' + complaint_entry.entry_id +
      '" type="text" onclick="this.select()" value="' + host +
      '"' + entry_status + '>' +
      '<button class="secondary inline-button" onclick="updateURI(event,' + complaint_entry.entry_id + ')">Update URI</button><br/>' +
      '<div class="complaint-selectize-col-wrapper">' +
      '<label class="content-label-sm">Edit Categories / Confidence Order</label>' +
      '<select id="' + input_cat + '" name="[' + input_cat + '][]" class="' + status_class + '" placeholder="Enter up to 5 categories" value=""></select>' +
      '</div>' +
      '<div class="domain-categories" >' +
      '<label class="content-label-sm">Inherit Categories From Main Domain</label><br/>' +
      '<ul id="main-domain-categories_' + complaint_entry.entry_id + '"></ul>'+
      '<button class="secondary inline-button" onclick="inheritCategories(' + complaint_entry.entry_id + ')">Inherit</button><br/>' +
      '</div>' +'</div><div class="col-xs-8">' +
      '<label class="content-label-sm">Internal Comment</label><br/>' +
      '<input class="nested-table-input complaint-comment-input" id="complaint_comment_' + complaint_entry.entry_id + '" type="text" onclick="this.select()" class="nested-table-input" value="' + internal_comment + '" placeholder="Add a comment." ' + entry_status + '><br/>'  +
      '<label class="content-label-sm customer-label">Customer Facing Comment</label><br/>' +
      '<input class="nested-table-input complaint-comment-input" id="complaint_resolution_comment_' + complaint_entry.entry_id + '" type="text" onclick="this.select()" value="' + resolution_comment + '" placeholder="Add a comment for the customer." ' + entry_status + '>' +
      '</div>' +
      '<div class="col-xs-4">' +
      '<label class="content-label-sm">Resolution</label><br/>' +
      complaint_submission_html +
      '</div></div></div></div></td></tr></table>'

  complaint_entry_html


## Complaint history dialog box. Includes tabs for domain history, complaint entry history, and xbrs history of the url.
window.history_dialog = (id, url) ->
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
        history_dialog_content =
          '<div class="dialog-content-wrapper">' +
          '<h4>' + url + '</h4>' +
          # Tab navigation
          '<ul class="nav nav-tabs dialog-tabs" role="tablist">' +
          '<li class="nav-item active" role="presentation">' +
          '<a class="nav-link" role="tab" data-toggle="tab" href="#domain-history-tab" aria-controls="domain-history-tab">Domain History</a>' +
          '</li>' +
          '<li class="nav-item" role="presentation">' +
          '<a class="nav-link" role="tab" data-toggle="tab" href="#complaint-history-tab" aria-controls="complaint-history-tab">Complaint Entry History</a>' +
          '</li>' +
          '<li class="nav-item" role="presentation">' +
          '<a class="nav-link" role="tab" data-toggle="tab" href="#xbrs-history-tab" aria-controls="xbrs-history-tab" onclick="get_xbrs_history(\'' + url + '\', this)">XBRS History</a>' +
          '</li>' +
          '</ul>' +

          # Tab content - beginning markup of first tab
          '<div class="tab-content dialog-tab-content">' +
          '<div class="tab-pane active" role="tabpanel" id="domain-history-tab">' +
          '<h5>Domain History</h5>'

        if json.entry_history.domain_history.length < 1
          history_dialog_content += '<span class="missing-data">No domain history available.</span>'
        else
          history_dialog_content +=
          '<table class="history-table"><thead><tr><th>Action</th><th>Confidence</th><th>Description</th><th>Time</th><th>User</th><th>Category</th></tr></thead>' +
          '<tbody>'
          # Build domain history table
          for entry in json.entry_history.domain_history
            entry_string =
            '<tr>' +
            '<td>' + entry['action'] + '</td>' +
            '<td>' + entry['confidence'] + '</td>' +
            '<td>' + entry['description'] + '</td>' +
            '<td>' + entry['time'] + '</td>' +
            '<td>' + entry['user'] + '</td>' +
            '<td>' + entry['category']['descr'] + '</td>' +
            '</tr>'
            history_dialog_content += entry_string
          # End domain history table
          history_dialog_content += '</tbody></table>'

        # End domain history tab start Complaint Entry Tab
        history_dialog_content +=
          '</div>' +
          '<div class="tab-pane" role="tabpanel" id="complaint-history-tab">' +
          '<h5>Complaint Entry History</h5>'

        if json.entry_history.complaint_history.length < 1
          history_dialog_content += '<span class="missing-data">No complaint entry history available.</span>'
        else
          history_dialog_content +=
            '<table class="history-table"><thead><th>Time</th><th>User</th><th>Details</th></thead>' +
            '<tbody>'

          # Build the complaint history table
          entry_row = ""
          for entry in json.entry_history.complaint_history
            entry_row = "<tr><td>" + entry[0] + '</td>'
            details_col = ""
            i = 0
            for change_key, change_entry of entry
              i = i + 1
              if i > 1
                for key, value of change_entry
                  if key == "whodunnit"
                    entry_row += "<td>" + value + "</td>"
                  else
                    details_col += '<span class="bold">' + key + ":</span> " + value[0] + " - " + value[1] + "<br/>"
            entry_row += '<td>' + details_col + '</td></tr>'
            history_dialog_content += entry_row
          history_dialog_content +=
            # End complaint history table
            '</tbody></table>'

        history_dialog_content +=
          # End complaint history table tab
          '</div>' +
          # Start XBRS Tab
          '<div class="tab-pane" role="tabpanel" id="xbrs-history-tab">' +
          '<h5>XBRS History</h5>' +
          '<table class="history-table xbrs-history-table" id="webcat-xbrs-history"></table>' +
          '</div>' +
          '</div>'

        # Only one history dialog open at a time - content gets swapped out
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
            minWidth: 800
            position: { my: "right top", at: "right top", of: window }
          $('#history_dialog').dialog('open')
    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)


## Fetches XBRS history of a url on click of the XBRS tab in history
window.get_xbrs_history = (url, tab) ->
  wrapper = $(tab).parents('.dialog-content-wrapper')[0]
  xbrs_table = $(wrapper).find('.xbrs-history-table')[0]
  xbrs_msg = $(wrapper).find('.xbrs-no-data-msg')[0]
  # Clear table of residual data
  $(xbrs_table).empty()
  if xbrs_msg?
    $(xbrs_msg).remove()
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/xbrs'
    method: 'POST'
    headers: headers
    data: {'url': url}
    success: (response) ->
      if response.data.length < 1
        $('<span class="missing-data xbrs-no-data-msg">No XBRS history available.</span>').insertBefore(xbrs_table)
      else
        # Cycle through and assign index values to column headers
        col_headers = []
        i = 0
        while i < response['columns'].length
          $(response['columns']).each ->
            col_defs = []
            col_defs["index"] = i
            col_defs["column"] = this.valueOf()
            col_headers.push(col_defs)
            i++

        col_indexes = []
        ctime_index = ''
        thead = '<thead><tr>'
        $(col_headers).each ->
          # We only want these specific columns
          if this.column == "domain" || this.column == "subdomain" || this.column == "ctime" || this.column == "mtime" || this.column == "mnemonic" || this.column == "operation" || this.column == "path"
            if this.column == "ctime"
              thead += '<th>Creation Time</th>'
              ctime_index = this.index
            else if this.column == "mtime"
              thead += '<th>Last Modified</th>'
            else
              thead += '<th>' + this.column + '</th>'
            col_indexes.push(this.index)
        thead += '</tr></thead>'

        row_data = []
        # For each row of data, cycle through and assign index to each column
        $(response['data']).each ->
          col_data = []
          d = 0
          while d < this.length
            $(this).each ->
              data = []
              data["index"] = d
              data["data"] = this.valueOf()
              col_data.push(data)
              d++
            row_data.push(col_data)

        # Sort rows by ctime
        row_data.sort (a,b) ->
          a1 = a[ctime_index]
          b1 = b[ctime_index]
          if a1.data == b1.data
            return 0
          if a1.data > b1.data then 1 else -1

        tbody = '<tbody>'
        $(row_data).each ->
          tbody += '<tr>'
          row = this
          $(row).each ->
            col = this.index
            col_content = this.data
            # If our column header indexes and our column data indexes match we create the column in the table
            if jQuery.inArray(col, col_indexes) != -1
              if jQuery.type(col_content) == 'string' || jQuery.type(this) == 'number'
                tbody += '<td>' + col_content + '</td>'
              else
                # is null - prevents weird json objects getting through
                tbody += '<td> - </td>'
          tbody += '</tr>'
        tbody += '</tbody>'

        $(xbrs_table).append(thead)
        $(xbrs_table).append(tbody)
    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)



parse_lookup_dialog_content = (json) ->
  lookup_dialog_content = '<div class="dialog-content-wrapper">' +
    '<h5> Lookup info for ' + json["prefix"] + '</h5>' +
    '<table class="lookup-table">' +
    '<tbody>'
  categories = json["current_categories"]
  $.each categories, (key, value) ->
    category = this
    active =  $(this).attr("is_active")
    if active == 1
      { confidence, mnemonic, name, category_id: cat_id, certainty: certainties } = this
      top_certainty = this.certainty[0].source_certainty

      category_row = '<tr><td>' + mnemonic + ' - ' + name + '</td></tr>'
      lookup_dialog_content = lookup_dialog_content + category_row
      lookup_dialog_content = lookup_dialog_content + '<tr> <table class="lookup-certanty-table">' +
        '<thead><tr><th></th><th>Confidence</th><th>Source</th><th>Certainty</th></tr></thead>' +
        '<tbody>'
      $(certainties).each ->
        {source_confidence, source_certainty, source_category, source: source_name } = this

        lookup_dialog_content = lookup_dialog_content + '<tr><td></td><td>' + source_confidence + '</td><td>' + source_name + '</td><td>' + source_certainty + '</td></tr>'
      lookup_dialog_content += '</tbody></table></tr>'
  lookup_dialog_content += '</tbody></table>'


window.lookup_dialog  = (id) ->
  std_msg_ajax(
    url:'/escalations/api/v1/escalations/webcat/complaint_entries/lookup'
    method: 'POST'
    data: {'id': id}
    success: (response) ->
      json = $.parseJSON(response)
      if json.error
        std_msg_error("<p>Something went wrong: #{json.error}","")
      else
        #parse this json properly
        lookup_dialog_content = parse_lookup_dialog_content(json)
        if $("#lookup_dialog").length
          lookup_dialog = this
          $("#lookup_dialog").html(lookup_dialog_content)
          $('#lookup_dialog').dialog('open')
        else
          lookup_dialog = '<div id="lookup_dialog" title="Lookup Information"></div>'
          $('body').append(lookup_dialog)
          $("#lookup_dialog").html(lookup_dialog_content)
          $('#lookup_dialog').dialog
            autoOpen: false
            minWidth: 400
            position: { my: "center top", at: "center top", of: window }
          $('#lookup_dialog').dialog('open')
    error: (response) ->
      std_msg_error("<p>Something went wrong: #{response.responseText}","")
  , this)


window.click_table_buttons = (complaint_table, button)->
  tr = $(button).closest('tr')
  row = complaint_table.row(tr)
  data = row.data()
  cat_select = '#input_cat_'+ data.entry_id
  if row.child.isShown()       # This row is already open - close it
    row.child.hide()
    tr.removeClass 'shown'
    tr.addClass 'not-shown'

    if verifyMasterSubmit() == false
      $('#master-submit').prop('disabled', true)

  else
    # Open this row
    row.child(format(row)).show()
    tr.removeClass 'not-shown'
    tr.addClass 'shown'
    td = $(tr).next('tr').find('td:first')
    unless $(td).hasClass 'nested-complaint-data-wrapper'
      $(td).addClass 'nested-complaint-data-wrapper'
#    debugger
    if ['NEW','ASSIGNED','PENDING', 'REOPENED', 'ACTIVE'].includes(data.status)
      $( cat_select ).selectize {
        persist: false,
        create: false,
        maxItems: 5,
        valueField: 'category_id',
        labelField: 'category_name',
        searchField: ['category_name', 'category_code'],
        options: AC.WebCat.createSelectOptions(),
        items: AC.WebCat.getCategoryIds(selected_options(data.category)),
        onItemAdd: ->
          if verifyMasterSubmit() == true
            $('#master-submit').prop('disabled', false)
        onItemRemove: ->
          if verifyMasterSubmit() == true
            $('#master-submit').prop('disabled', false)
          else
            $('#master-submit').prop('disabled', true)
      }
    else
      # need to initialize the selectize function but disable it here if entry is completed
      $completed_selectize = $( cat_select ).selectize {
        persist: false,
        create: false,
        maxItems: 5,
        valueField: 'category_id',
        labelField: 'category_name',
        searchField: ['category_name', 'category_code'],
        options: AC.WebCat.createSelectOptions(),
        items: selected_options(data.category),
      }
      select_complete = $completed_selectize[0].selectize
      select_complete.disable()

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

    if verifyMasterSubmit() == true
      $('#master-submit').prop('disabled', false)

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

window.fetch_complaints = () ->
  std_msg_ajax(
    method: 'POST'
    url: '/escalations/api/v1/escalations/webcat/complaints/fetch'
    data: {}
    success_msg: 'Complaint updates requested from Talos-Intelligence.  Please refresh your page shortly.'
    error_prefix: 'Error fetching complaints.'
  )


open_selected = (selected_rows, toggle) ->
  for selected_row in selected_rows.data()
    { viewable, subdomain, domain, path, ip_address } = selected_row
    if viewable == toggle

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

window.open_viewable = () ->
  selected_rows = $('#complaints-index').DataTable().rows()
  open_selected(selected_rows, "true")
window.open_nonviewable = () ->
  selected_rows = $('#complaints-index').DataTable().rows()
  open_selected(selected_rows, "false")
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

toggle_selected = (selectedRows, expand)->
  selectState = $('.selected')
  for i in [0..selectedRows.length]
    if expand
      if !$(selectedRows[i]).hasClass('shown')
        $(selectedRows[i]).find('.expand-row-button-inline').click()
    else
      if $(selectedRows[i]).hasClass('shown')
        $(selectedRows[i]).find('.expand-row-button-inline').click()
        $(selectedRows[i]).addClass('selected')
  $(selectState).addClass('selected')


# webcat: hot key/shortcut to pin toolbar
$(document).keypress (e) ->
  if e.which == 54 && e.ctrlKey == true
    pin_to_top()

# webcat: pin/unpin toolbar to top on webcat
window.pin_to_top = () ->
  if !$('#pin-to-top').hasClass('pinned')
    toolbar = $('#webcat-index-toolbar').detach()  # detach every time
    $(toolbar).addClass('pinned-toolbar')
    $('#nav-banner').append(toolbar)

    $('#pin-to-top span').text('Unpin Toolbar from Top')
    $('#pin-to-top').attr('title', 'Unpin Toolbar from Top (Ctrl + 6)')
    $('#page-content-wrapper').css('padding-top','60px')
    $('#pin-to-top').addClass('pinned')
    $('body').addClass('pinned-toolbar-true')
  else  # already pinned to top?
    toolbar = $('#webcat-index-toolbar').detach()
    $(toolbar).removeClass('pinned-toolbar')
    $('.webcat-main-area').prepend(toolbar)

    $('#pin-to-top span').text('Pin Toolbar to Top')
    $('#pin-to-top').attr('title', 'Pin Toolbar to Top (Ctrl + 6)')
    $('#page-content-wrapper').css('padding-top','15px')
    $('#pin-to-top').removeClass('pinned')
    $('body').removeClass('pinned-toolbar-true')

window.collapse_selected =()->
  selectedRows = $('.selected')
  expand = false;
  toggle_selected(selectedRows, expand)

window.collapse_all =()->
  selectedRows = $('table#' + 'complaints-index' + ' tr[role="row"]')
  expand = false;
  toggle_selected(selectedRows, expand)

window.expand_selected =()->
  selectedRows = $('.selected')
  expand = true;
  toggle_selected(selectedRows, expand)

window.expand_all =()->
  selectedRows = $('table#' + 'complaints-index' + ' tr[role="row"]')
  expand = true;
  toggle_selected(selectedRows, expand)

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

window.triggerTooltips = (item) ->
  $('.nested-tooltipped').tooltipster
    theme: [
      'tooltipster-borderless'
      'tooltipster-borderless-customized'
    ]
    side: 'bottom'
  return

window.master_submit = () ->
  data = []

  $('#loader-modal').modal({
    keyboard: false
  })

  $('.selected + tr td.nested-complaint-data-wrapper').each ->
    entry_id = $(this).find('tr').attr('entry_id')
    row_id = $(this).find('tr').attr('row_id')
    type = $(this).find('tr').attr('type')

    if type == 'submit_changes' && entry_id && row_id
      prefix = $(this).find("#complaint_prefix_#{entry_id}")[0].value

      category_names = []
      categories = ""
      if $(this).find("#input_cat_#{entry_id}").val()
        categories = $(this).find("#input_cat_#{entry_id}").val().toString()
      category_name = $(this).find("#input_cat_#{entry_id}").next('.selectize-control').find('.item')
      category_name.each ->
        category_names.push($(this).text())
      category_names = category_names.toString()
      status = $(this).find("[name=resolution#{entry_id}]:checked").val()
      comment = $(this).find("#complaint_comment_#{entry_id}")[0].value
      resolution_comment = $(this).find("#complaint_resolution_comment_#{entry_id}")[0].value

      if (categories.length > 0 && status == 'FIXED') || ((categories.length == 0) && (status == 'INVALID' || status == 'UNCHANGED'))
        data.push({entry_id: entry_id, error: false, row_id: row_id, prefix: prefix, categories: categories, category_names: category_names, status: status, comment: comment, resolution_comment: resolution_comment})
      else if status == 'UNCHANGED' || status == 'INVALID'
        data.push({entry_id: entry_id, error: false, row_id: row_id, prefix: prefix, categories: categories, category_names: category_names, status: status, comment: comment, resolution_comment: resolution_comment})
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

          $('#input_cat_'+ entry.entry_id).selectize {
            persist: false,
            create: false,
            maxItems: 5
            valueField: 'category_id',
            labelField: 'category_name',
            searchField: ['category_name', 'category_code'],
            options: AC.WebCat.createSelectOptions()
            items: selected_options(entry.categories)
          }
          $('#input_cat_pending'+ entry.entry_id).selectize {
            persist: false,
            create: false,
            maxItems: 5
            valueField: 'category_id',
            labelField: 'category_name',
            searchField: ['category_name', 'category_code'],
            options: AC.WebCat.createSelectOptions()
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
        $('#loader-modal').modal 'hide'
        std_msg_error(error_msg,"")
      else
        $('#loader-modal').modal 'hide'
        std_msg_success('Success',["All complaints successfully processed."], reload: true)

      tds = $('#complaints-index tbody').closest('td')
      for td in tds
        if td.className == ''
          td.classList.add('nested-complaint-data-wrapper')

    error: (response) ->
      $('#loader-modal').modal 'hide'
      std_msg_error("Unable to submit changes for selected entries.","", reload: false)

  , this)


window.verifyMasterSubmit = () ->
  boolean = false
  if $('.shown').length > 0 && $('.has-items').length > 0
    $('.has-items').each ->
      if (!$(this).closest('tr').hasClass("pending"))
        boolean = true
  return boolean

$ ->
  $('#cat_new_url_modal').on 'shown.bs.modal', ->
    $('#url_1').focus()
    return

  $('#cat-urls-diff').click ->
    if $('#cat-urls-diff').prop('checked')
      $('#categorize-same-form').hide()
      $('#categorize-diff-form').show()

  $('#cat-urls-same').click ->
    if $('#cat-urls-same').prop('checked')
      $('#categorize-diff-form').hide()
      $('#categorize-same-form').show()

  $(document).on 'change', '.resolution_radio_button', ->
    $('#master-submit').prop('disabled', false)

  $('.expand-all').click ->
    complaint_table = $('#complaints-index').DataTable()
    td = $('#complaints-index').find('td.expandable-row-column')

    td.each ->
      tr = $(this).closest('tr')
      row = complaint_table.row(tr)

      unless row.child.isShown()

        row.child(format(row)).show()
        tr.addClass 'shown'

        td = $(tr).next('tr').find('td:first')
        $(td).addClass 'nested-complaint-data-wrapper'
        unless $(td).hasClass 'nested-complaint-data-wrapper'
          tr.find('td:first').addClass 'nested-complaint-data-wrapper'

        $('#input_cat_'+ row.data().entry_id).selectize {
          persist: false,
          create: false,
          maxItems: 5,
          valueField: 'category_id',
          labelField: 'category_name',
          searchField: ['category_name', 'category_code'],
          options: AC.WebCat.createSelectOptions()
          items: selected_options(row.data().category)
        }

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


  $('#complaints_check_box').click ->
    if $('#complaints_check_box').prop('checked')
      $('#complaints-index').DataTable().rows( { page: 'current' } ).select()
    else
      $('#complaints-index').DataTable().rows().deselect()
    return

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

  # If a stupidly long email address is returned it will wrap
  # rather than pushing the column into the column beside it
  $('.email-row').find('.case-history-author').each ->
    if $(this).text().length > 28
      $(this).addClass('break-word')


  $('#complaint_ticket_status').click ->
    selected_rows = $('#complaints-index').DataTable().rows('.selected')
    if (selected_rows[0].length > 0)
      $('.ticket-status-radio-label').click ->
        $('#loader-modal').modal()
        radio_button = $(this).prev('.ticket-status-radio')
        $(radio_button[0]).trigger('click')
        entry_ids = []
        i = 0
        while i < selected_rows[0].length
          entry_ids.push(selected_rows.data()[i].entry_id)
          i++
        data = {
          complaint_entry_ids: entry_ids,
          resolution_name: $(radio_button).attr('id')
        }

        std_msg_ajax(
          method: 'POST'
          url: '/escalations/api/v1/escalations/webcat/complaint_entries/bulk_update_entry_resolution'
          data: data
          success_reload: true
          error: (response) ->
            std_api_error(response, "Some categories could not be set.", reload: true)
        )
    else
      std_msg_error('No rows selected', ['Please select at least one row.'])

