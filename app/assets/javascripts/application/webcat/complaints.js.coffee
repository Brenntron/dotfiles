table_page = 0

$(document).on 'click', '.paginate_button', ->
  complaint_table = $('#complaints-index').DataTable().context
  if complaint_table.length > 0
    table = $('#complaints-index').DataTable()
    table_page = table.page.info().page

$(document).on 'change','.nested-table-input','.selectize-input', ->
  touchedFormChange(this.dataset.domain)

#### WBNP Reporting ####
webcat_loader_timeout = ''

$(document).ready ->
  if window.location.pathname == '/escalations/webcat/reports'
    build_imports_table()

  sessionStorage.removeItem("touchedForm")
  loader = $('#inline-webcat')
  $(this).bind(
    ajaxStart: () ->
      webcat_loader_timeout = setTimeout ->
        loader.removeClass('hidden')
      , 500
    ajaxStop: () ->
      clearTimeout(webcat_loader_timeout)
      loader.addClass('hidden')
    )
  if ($('body').hasClass('escalations--webcat--complaints-controller') || $('body').hasClass('escalations--webcat--reports-controller')) &&
     $('body').hasClass('index-action')
    window.check_wbnp_status()

window.change_ticket_view = (type,button) ->

  checked = $('.imports_check_box:checked')

  if $(button).hasClass('active-view')
    #if view is already active, do nothing
    return

  switch type
    when 'ticket'
      if checked.length == 0
        #if ticket view selected without any checked, show error and do nothing
        std_msg_error("Select at least one ticket to view.", [], reload: false)
        return
      else
        #else build (or show previously built) tickets
        build_ticket_view(checked,"bulk")
        $('.mothra-header').text('Import Results')
    when 'list'
      $('.mothra-header').text('Jira Imports')
      $('.ticket-rows').addClass('hidden') #ticket rows must be individually hidden
      $('.ticket-rows').removeClass('vis-ticket')
  # show/hide appropriate elements
  $('#webcat-imports-index_wrapper, .webcat-ticket-view').toggleClass('hidden')
  $('.list-button, .view-tickets').toggleClass('active-view')

window.build_single_row = (rd, urls) ->
  { issue_key, submitter, status, result, imported_at } = rd

  if result && status != result
    status = "#{status.toUpperCase()} - #{result}"

  row_data = {
    'Jira Ticket': "<span class='jira-ticket-id'>#{issue_key}</span>",
    'Submitter': submitter,
    'Imported On': imported_at,
    'Status': status
  }

  ticket_html = "<div class='col-xs-12 col-sm-10 ticket-rows vis-ticket' id='#{issue_key}'>"
  #build upper data
  for title, content of row_data

    if !content then content = "<span class='missing-data'>Not available</span>"

    ticket_html += "<div class='col-xs-6 no-padding-left'>
                            <label class='data-report-label'>#{title}</label>
                            <span class='data-report-content'>#{content}</span>
                          </div>"
  ticket_html += "<div class='col-xs-12 no-padding-left urls-container'>
                  <label class='data-report-label'>Urls<label></div>"
  #build table data
  table_html = "<table>
                    <thead>
                      <tr>
                        <th>Original</th>
                        <th>Sanitized</th>
                        <th>Entry ID</th>
                        <th>Bast Response</th>
                    </tr>
                    </thead>
                  <tbody>"

  if !urls.length
    table_html +="<tr><td colspan=4 ><span class='missing-data'> No URLs Available</span></td></tr>"
  else
    for url in urls
      {domain, url, complaint_id, imported, verdict_reason}= url
      unsanitized = '-'
      entry = '-'

      if verdict_reason
        imported += " - #{verdict_reason}"

      if complaint_id
        entry = "<span class='ticket-id'>#{complaint_id}</span>"

      if domain
        unsanitized = url + domain

      #this will need to be changed 5sure
      table_html += "<tr>
                          <td>#{url}</td>
                          <td>#{unsanitized}</td>
                          <td>#{entry}</td>
                          <td>#{imported}</td>
                        </tr>"

  table_html += "</tbody></table></div></div>"
  ticket_html += table_html

  $('.webcat-ticket-view').append(ticket_html)

window.build_ticket_view = (checked, view) ->
  table =  $('#webcat-imports-index').DataTable()

  if view == 'single'
    checked = [checked]

  for check, index in checked
    row = $(check).closest('tr')
    id = $(check).attr('value')
    el = $("##{id}")

    if el.length > 0
      # if we have already built this ticket view, show it
      el.removeClass('hidden')
      if checked.length > 1
        el.addClass('vis-ticket')
    else
      # if we haven't built this ticket view, build it
      rd = table.row( row ).data()
      get_bast_data(rd.id).then( build_single_row.bind(null, rd) )

  if view == 'single'
    $('.mothra-header').text('Import Results')
    $('#webcat-imports-index_wrapper, .webcat-ticket-view').toggleClass('hidden')
    $('.list-button, .view-tickets').toggleClass('active-view')

$(document).on 'click', '#bulk-ticket-select',->
  checked = $(this).prop('checked')
  $('.imports_check_box').prop('checked', checked)

$(document).on 'click', '.imports_check_box',->
  num_checked = $('.imports_check_box:checked').length

  if num_checked == $('.imports_check_box').length
    $('.imports_check_box').prop('checked', true)
  if num_checked == 0
    $('.imports_check_box').prop('checked', false)

$(document).on 'click', '#show-failed, #show-complete',->
  table = $('#webcat-imports-index').DataTable()
  show_failed = $('#show-failed').prop('checked')
  show_complete = $('#show-complete').prop('checked')

  table.rows().every( ()->
    status = this.data().status
    switch status
      when'Failure'
        if show_failed
          $('.failed').show()
        else
          $('.failed').hide()
      else
        if show_complete
          $('.complete-pending').show()
        else
          $('.complete-pending').hide()
  )

window.checked_row_data = ()->
  table = $('#webcat-imports-index').DataTable()
  rows = $('.imports_check_box:checked').closest('tr')
  data = table.rows(rows).data()
  return data

$(document).on 'click', '.imports_check_box', ->
  retry_button = $('.toolbar-button.retry-button')

  can_retry = false
  checked_data = checked_row_data() || [];

  for row in checked_data
    if row.status == 'Failure'
      can_retry = true
      break

  if can_retry
    retry_button.removeAttr('disabled')
  else
    retry_button.attr('disabled', true)

window.retry_imports = (id)->
  if id
    ids = [id]
  else
    ids = []
    checked_row_data().map( (r) -> ids.push(parseInt(r.id)) )
  std_msg_ajax(
    method: 'GET'
    url: '/escalations/api/v1/escalations/jira_import_tasks/retry_import'
    data: {
        task_ids:ids
      }
    success: (response) ->
      $('#webcat-imports-index').DataTable().ajax.reload()
    error: (response) ->
      std_api_error(response, 'Error retrying import.', reload: false)
  )


window.build_imports_table = () ->
  $('#webcat-imports-index').DataTable(
    serverSide: true
    processing: true
    ajax: {
      url: "/escalations/webcat/jira_import_tasks.json"
    }
    order:[]
    dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
    language: {
      search: "_INPUT_"
      searchPlaceholder: "Search within table"
    }
    initComplete: (data,type,full,meta) ->
      $('#webcat-imports-index_filter input').addClass('table-search-input');
    columnDefs: [
      {
        targets: [ 0 ]
        orderable: false
        searchable: false
      }
      {
        targets: [ 0,1,2,3,4,5 ]
        defaultContent:'-'
      }
    ]
    createdRow:(row, data, dataIndex) ->
      {status} = data
      if status == 'Failure'
        $(row).addClass('failed')
      else
        $(row).addClass('complete-pending')
    columns:[
      {
        data:'issue_key',
        render: (data,type,full,meta) ->
          return "<input type='checkbox' name='cbox' class='imports_check_box' id='cbox#{data}' data=#{JSON.stringify(full)} value=#{data} />"
      },
      {
        data: 'issue_key',
        render:(data,type,full,meta)->
          html = "<span class='jira-ticket-id' onclick='build_ticket_view(this, \"single\")' value='#{data}'>#{data}</span>"
          return html
      },
      {data: 'submitter'},
      {data: 'imported_at'},
      {
        data: 'total_urls'
        render: (data,type,full,meta) ->
          {unimported_urls, total_urls, imported_urls}=full
          return "<span class='total-imports'>#{total_urls} total</span> (#{imported_urls}|#{unimported_urls})"
      },
      {
        data: 'result'
        render: (data,type,full,meta) ->
          {status, result, id}=full

          if result && result != status
            html = "<span>#{status} - #{result}</span>"
          else
            html = "<span>#{status}</span>"

          if status == 'Failure'
            html += "<button class='inline-retry-button retry-button tooltipped tooltipstered' title='Retry' onclick='retry_imports(#{id})'></button>"

          return html
      },
      {
        data: 'status'
        visible: false
      }
    ]
  )
# WBNP - Get report id

window.get_bast_data = (id) ->
  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/jira_import_tasks/#{id}/submitted_urls"
    data: {}
    success: (response) ->
      return response.urls
    error: (response) ->
      std_api_error(response, 'Error fetching bast data', reload: false)
  )

window.export_all_jira_tasks = ()->
  form = $('#jira-tasks-disputes-export-form')

  $('#jira-tasks-filter-input').val([])
  form.submit()

window.export_selected_jira_tasks = ()->
  form = $('#jira-tasks-disputes-export-form')

  selected_tasks = $('.imports_check_box:checked').map((i, el) => el.value).get()
  if selected_tasks.length <= 0
    std_msg_error('Error: Nothing selected.',"", reload: false)
  else      
    $('#jira-tasks-filter-input').val(selected_tasks)
    form.submit()
\
window.fetch_wbnp_data = () ->
  $('#fetch_wbnp').attr('disabled', true)
  $('#fetch_wbnp').addClass('esc-tooltipped')
  $('.wbnp-loading-spinner').show()
  # Set status on header to checking
  top_status = $('.top-area-bar').find('.wbnp-report-status')[0]
  $(top_status).text('Checking...')

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
  if $('#wbnp-full-report').length > 0
    # this is a webcat manager and they get the full WBNP report
    data = {}
    full_report = true
    # Turn on the checking message if needed
    unless $('#current-wbnp-report .wbnp-status').hasClass('status_complete')
      wbnp_check = $('.wbnp-full-report-title-status')[0]
      $(wbnp_check).addClass('active')
      wbnp_status = 'Checking report status...'
      $(wbnp_check).text(wbnp_status)

  else
    data = {wbnp_report_id: wbnp_report_id}
    full_report = false

  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/webcat/complaints/wbnp_report_status"
    data: data
    success: (response) ->
      $('.wbnp-loading-spinner').hide()
      # Turn off loader indicator
      if full_report == true
        # Clear old data
        $('.wbnp-status').empty();
        $('.wbnp-status-msg').empty();
        $('.wbnp-full-report-table tbody').empty();
        $('.wbnp-notes').empty();

        curr_report = response.data[0]
        last_report = response.data[1]
        currentSkippedText = if curr_report.cases_skipped? then curr_report.cases_skipped else '0'

        # Add current report info to top bar report area

        $('.wbnp-report-status').text(curr_report.status)
        $('#wbnp-report-attempted').text(curr_report.total_new_cases)
        $('#wbnp-report-succeeded').text(curr_report.cases_imported)
        $('#wbnp-report-rejected').text(curr_report.cases_failed)
        $('#wbnp-quick-report-skipped').text(currentSkippedText)
        $('#wbnp-full-report-skipped').text(currentSkippedText)

        # Build the full report for webcat managers
        wbnp_dialog = $('#wbnp-full-report')

        # Current report:
        if curr_report.status == 'complete'
          $('#current-wbnp-report .wbnp-status').addClass('status_complete')
        else
          $('#current-wbnp-report .wbnp-status').removeClass('status_complete')
        $('#current-wbnp-report .wbnp-status').text(curr_report.status)
        $('#current-wbnp-report .wbnp-status-msg').text(curr_report.status_message)
        current_table = $('#current-wbnp-report .wbnp-full-report-table')
        curr_table_content = '<tr><td>' + curr_report.id + '</td><td>' + curr_report.attempts + '</td><td>' + curr_report.total_new_cases + '</td><td>' + curr_report.cases_imported + '</td><td>' + curr_report.cases_failed + '</td><td>' + currentSkippedText + '</td><td>' + curr_report.created_at + '</td><td>' + curr_report.updated_at + '</td></tr>'
        $(current_table).append(curr_table_content)
        $('#current-wbnp-report .wbnp-notes').html(curr_report.notes)

        # Previous report:
        if last_report?
          lastSkippedText = if last_report.cases_skipped? then last_report.cases_skipped else '0'
          if last_report.status == 'complete'
            $('#previous-wbnp-report .wbnp-status').addClass('status_complete')
          else
            $('#previous-wbnp-report .wbnp-status').removeClass('status_complete')
          $('#previous-wbnp-report .wbnp-status').text(last_report.status)
          $('#previous-wbnp-report .wbnp-status-msg').text(last_report.status_message)
          prev_table = $('#previous-wbnp-report .wbnp-full-report-table')
          prev_table_content = '<tr><td>' + last_report.id + '</td><td>' + last_report.attempts + '</td><td>' + last_report.total_new_cases + '</td><td>' + last_report.cases_imported + '</td><td>' + last_report.cases_failed + '</td><td>' + lastSkippedText + '</td><td>' + last_report.created_at + '</td><td>' + last_report.updated_at + '</td></tr>'
          $(prev_table).append(prev_table_content)
          $('#previous-wbnp-report .wbnp-notes').html(last_report.notes)

        # Keep checking / updating if Current report is unfinished
        if curr_report.status != 'complete'
          if $('.wbnp-full-report-title-status').length == 0
            $('.ui-dialog .ui-dialog-title').append('<span class="wbnp-full-report-title-status"></span>')
          wbnp_check = $('.wbnp-full-report-title-status')[0]
          wbnp_status = 'Checking report status in 45 seconds...'
          $(wbnp_check).removeClass('active')
          $(wbnp_check).text(wbnp_status)
          setTimeout(check_wbnp, 45000)
        else
          $('.wbnp-full-report-title-status').remove()



      else
        curr_report = response.data[0]
        currentSkippedText = if curr_report.cases_skipped? then curr_report.cases_skipped else '0'
        # Add current report info to top bar report area
        $('.wbnp-report-status').text(curr_report.status)
        $('#wbnp-report-attempted').text(curr_report.total_new_cases)
        $('#wbnp-report-succeeded').text(curr_report.cases_imported)
        $('#wbnp-report-rejected').text(curr_report.cases_failed)
        $('#wbnp-quick-report-skipped').text(currentSkippedText)
        $('#wbnp-full-report-skipped').text(currentSkippedText)

    error: (response) ->
      $('.wbnp-loading-spinner').hide()

      std_msg_error("Unable to pull wbnp status", [], reload: false)
  )

window.touchedFormChange = (url) ->
  urls_touched = (sessionStorage.getItem("touchedForm")|| "" )

  if !urls_touched.includes(url)
    url_items = urls_touched.split(",")
    url_items = url_items.filter((item) -> return item)
    url_items.push(url)
    urls_touched = url_items.join(",")
  sessionStorage.setItem("touchedForm", urls_touched)

window.removeTouchedFormChange = (url) ->
  urls_touched = (sessionStorage.getItem("touchedForm")|| "" )

  if urls_touched.includes(url)
    url_items = urls_touched.split(",")
    url_items = url_items.filter((item) -> return item)
    url_index = url_items.indexOf(url)
    url_items.splice(url_index, 1)
    urls_touched = url_items.join(",")
  sessionStorage.setItem("touchedForm", urls_touched)

getTouchedFormCount = ()->
  form_item = (sessionStorage.getItem("touchedForm") || "")
  form_item = form_item.split(",")
  form_item = form_item.filter((item) -> return item)
  return form_item.length

window.updateURI = (event, complaint_entry_id) ->
  event.preventDefault()

  uri = $("#complaint_prefix_#{complaint_entry_id}").val()

  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/webcat/complaints/update_uri"
    data: {complaint_entry_id: complaint_entry_id, uri: uri }
    success: (response) ->
      {current_categories, category, wbrs_score, domain, subdomain, path, status} = response.json

      if subdomain
        qual_subdomain = subdomain + '.' + domain
      else
        qual_subdomain = domain

      $(".simple-nested-table#entry-table-#{complaint_entry_id} tbody > tr").remove()

      if 'ip' == status
        std_msg_error("Cannot edit IP entries.","")
      else
        $("#domain_#{complaint_entry_id}").tooltipster('content', uri);
        $("#site-search-#{complaint_entry_id}").tooltipster('content', uri);
        $("#entry-uri-#{complaint_entry_id}").tooltipster('content', uri);
        $.each current_categories, (key, entry) ->
          $(".simple-nested-table#entry-table-#{complaint_entry_id}").append("<tr><td>#{entry.confidence}</td><td>#{entry.mnem} - #{entry.descr}</td><td>#{entry.top_certainty}</span></td></tr>")

        $("#domain_#{complaint_entry_id}").text(domain)
        $("#subdomain_#{complaint_entry_id}").text(subdomain)
        $("#path_#{complaint_entry_id}").text(path)
        $("#category_#{complaint_entry_id}").text(category)
        $("#wbrs_score_#{complaint_entry_id}").text(wbrs_score)
        query_who_params = "#{domain}, #{complaint_entry_id}"
        $("#entry-uri-#{complaint_entry_id}").html("<a href='http://#{uri}' target='_blank' onclick='select_cat_text_field(#{complaint_entry_id})' >#{uri}</a>")
        $("#site-search-#{complaint_entry_id}").html("<a href='https://www.google.com/search?q=site%3A#{uri}' target='_blank' onclick='select_cat_text_field(#{complaint_entry_id})'>#{uri}</a>")

        $("#lookup-#{complaint_entry_id}").replaceWith('<button class="secondary" id="lookup-' + complaint_entry_id + '" data-fqdn="' + qual_subdomain + '" onclick="WebCat.RepLookup.whoIsLookups(' + complaint_entry_id  + ',\'' + qual_subdomain + '\')">Whois</button>')
        $("#history-#{complaint_entry_id}").replaceWith('<button class="secondary" id="history-' + complaint_entry_id + '" onclick="history_dialog(' + complaint_entry_id + ',\'' + uri + '\')">History</button>')
    error: (response) ->
      std_msg_error("Unable to update URI", [response.responseJSON.message], reload: false)

 )

processSubmitNewURL = () ->
  data = {}
  isEmpty = true
  $('#categorize-urls').dropdown('toggle')
  for i in [1...6] by 1
    categories = []
    for j in [0...5] by 1
      if $("#cat_new_url_#{i}")[0][j]
        categories.push($("#cat_new_url_#{i}")[0][j].text)

    data[i] = {url: $("#url_#{i}").val(), category_names: categories, category_ids: $("#cat_new_url_#{i}").val()}

    if data[i].url.length > 0 && data[i].category_ids != null
      isEmpty = false

  if !isEmpty
    std_msg_ajax(
      url:'/escalations/api/v1/escalations/webcat/complaints/cat_new_url'
      method: 'POST'
      data: {data: data}
      success: (response) ->
        timesTouched = 0
        popular_entries = []
        message = ""
        for key, val of response
          if val.popular == true
            popular_entries.push(val.url)

        if popular_entries.length > 0
           message = "Pending complaint entries have been created for #{popular_entries.join(',')}"
        else
           message = "No pending complaint entries have been created"

        reload_message = "</br><a href='.'>Refresh the page</a> to see the result"
        std_msg_success(
          'URLs categorized successfully',
          [message, "All other entries have been submitted directly to WBRS.", reload_message],
          reload: false,
          complete: (->
            # clear url inputs
            $('#url_1').val('')
            $('#url_2').val('')
            $('#url_3').val('')
            $('#url_4').val('')
            $('#url_5').val('')
            # clear categories inputs
            $('#cat_new_url_1')[0].selectize.clear()
            $('#cat_new_url_2')[0].selectize.clear()
            $('#cat_new_url_3')[0].selectize.clear()
            $('#cat_new_url_4')[0].selectize.clear()
            $('#cat_new_url_5')[0].selectize.clear()
            )
        )
      error: (response) ->
        if response.responseText.includes('Either no products have been defined to enter bugs against or you have not been given access to any.')
          std_api_error(response, "Please make sure you have the appropriate permissions in Bugzilla. Unable to categorize url.", reload: false)
        else
          std_api_error(response, "Unable to categorize url.", reload: false)
    )
  else
    std_msg_error("Unable to categorize", ["Please confirm that a URL and at least one category for each desired entry exists."], reload: false)

window.cat_new_url = ()->
  timesTouched = getTouchedFormCount()
  if timesTouched > 1
    std_msg_confirm(
      "You have made " + timesTouched + " changes on this page. Do you want to proceed with categorizing this new item? It will reload the page and you will lose your changes.",
      [],
      {
        reload: false,
        confirm_dismiss: true,
        confirm: ->
          processSubmitNewURL()
      })
  else
    processSubmitNewURL()

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

window.multiple_url_categorization = () ->
  loader = $('.lookup-drop-loader')
  loader.removeClass('hidden')

  urls = $("#categorize_urls").val().split(/\n/)
  category_ids = $("#multi_cat_url_cats").val()
  category_names = []
  for category in $("#multi_cat_url_cats")
    for i in [0..5] by 1
      if category[i]
        category_names.push(category[i].text)

  if $("#categorize_urls").val() != "" && category_ids != null && category_names != null
    std_msg_ajax(
      url:'/escalations/api/v1/escalations/webcat/complaints/multi_cat_new_url'
      method: 'POST'
      data: {urls: urls, category_names: category_names, category_ids: category_ids}
      success: (response) ->
        loader.addClass('hidden')
        std_msg_success('Success',["URLs/IPs successfully categorized."], reload: true)
      error: (response) ->
        loader.addClass('hidden')
        std_msg_error('Error' + ' ' + response.responseJSON.message,"", reload: false)

    )
  else
    std_msg_error('Error', ['Please check that a URL/IP has been inputted and that at least one category was selected.'], reload: false)


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

name_servers =(server_list)->
  if undefined == server_list
    ''
  else
    text = ""
    for server in server_list
      text += server + '<br>'
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

window.review_bulk_submit = () ->
  selected_rows = $("tr.highlight-second-review.shown")
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
    data: {data: [{'id': entry_id,'prefix': prefix,'commit':status,'status':resolution,'comment':comment, 'resolution_comment': resolution_comment, 'categories': categories, 'category_names':named_categories }]}
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

processSubmitEntry = (entry_id,row_id) ->
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
  uri_as_categorized = $('#complaint_prefix_'+entry_id)[0].value
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
      data: {'id': entry_id, 'prefix': prefix, 'categories':categories, 'category_names':category_names, 'status':resolution_status, 'comment':comment, 'resolution_comment': resolution_comment, 'uri_as_categorized': uri_as_categorized }
      success: (response) ->
        {categories, error, uri, domain, subdomain, path, status, display_name} = $.parseJSON(response)

        if !error
          $("#submit_changes_#{entry_id}").addClass('hidden')
          $("#reopen_#{entry_id}").removeClass('hidden')

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
          nested_tooltip()

          $('#input_cat_'+ temp_row.data().entry_id).selectize {
            persist: false,
            create: false,
            maxItems: 5,
            closeAfterSelect: true,
            valueField: 'category_id',
            labelField: 'category_name',
            searchField: ['category_name', 'category_code'],
            options: AC.WebCat.createSelectOptions('#input_cat_'+ temp_row.data().entry_id)
            items: selected_options(categories)
          }

          $('#input_cat_pending'+ temp_row.data().entry_id).selectize {
            persist: false,
            create: false,
            maxItems: 5,
            closeAfterSelect: true,
            valueField: 'category_id',
            labelField: 'category_name',
            searchField: ['category_name', 'category_code'],
            options: AC.WebCat.createSelectOptions('#input_cat_pending'+ temp_row.data().entry_id)
            items: selected_options(categories)
          }
          unless status == 'COMPLETED'
            $('#input_cat_'+ temp_row.data().entry_id).selectize {
              persist: false,
              create: false,
              maxItems: 5,
              closeAfterSelect: true,
              valueField: 'category_id',
              labelField: 'category_name',
              searchField: ['category_name', 'category_code'],
              options: AC.WebCat.createSelectOptions('#input_cat_'+ temp_row.data().entry_id)
              items: selected_options(temp_row.data().category_names)
            }
          else
            # For entries that are 'Completed', we need to initialize the selectize function
            # and then disable it
            $completed_selectize = $('#input_cat_'+ temp_row.data().entry_id).selectize {
              persist: false,
              create: false,
              maxItems: 5,
              closeAfterSelect: true,
              valueField: 'category_id',
              labelField: 'category_name',
              searchField: ['category_name', 'category_code'],
              options: AC.WebCat.createSelectOptions('#input_cat_'+ temp_row.data().entry_id)
              items: selected_options(temp_row.data().category_names)
            }
            select_complete = $completed_selectize[0].selectize
            select_complete.disable()

          removeTouchedFormChange(uri)
          timesTouched = 0
          $("#complaint_prefix_#{entry_id}").val(uri)
          $("#domain_#{entry_id}").text(domain)
          $("#subdomain_#{entry_id}").text(subdomain)
          $("#path_#{entry_id}").text(path)
          $("#entry-uri-#{entry_id}").html("<a href='http://#{uri}' target='_blank' onclick='select_cat_text_field(#{entry_id})' >#{uri}</a>")
          $("#site-search-#{entry_id}").html("<a href='https://www.google.com/search?q=site%3A#{uri}' target='_blank' onclick='select_cat_text_field(#{entry_id})'>#{uri}</a>")

        else
          $("#submit_changes_#{entry_id}").removeClass('hidden')
          $("#reopen_#{entry_id}").addClass('hidden')
          std_msg_error("Unable to update complaint entry",[error], reload: false)

        tds = $('#complaints-index tbody').closest('td')
        for td in tds
          if td.className == ''
            td.classList.add('nested-complaint-data-wrapper')

      error: (response) ->
        $("#submit_changes_#{entry_id}").removeClass('hidden')
        $("#reopen_#{entry_id}").addClass('hidden')
        std_msg_error(response,"", reload: false)
    , this)


## Called when user submits categories / information to close a ticket
window.updateEntryColumns = (entry_id,row_id) ->
  timesTouched = getTouchedFormCount()
  if timesTouched > 1
    std_msg_confirm(
      "You have made " + timesTouched + " changes on this page. Do you want to proceed with updating this entry? It will reload the page and you will lose your changes.",
      [],
      {
        reload: false,
        confirm_dismiss: true,
        confirm: ->
          processSubmitEntry(entry_id,row_id)
      })
  else
    processSubmitEntry(entry_id,row_id)


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

window.select_cat_text_field = (id) ->
  if (typeof numericalValue)
    $( "#category_input"+id ).select();

window.edit_selected_complaints = () ->
  selected_rows = $('#complaints-index').DataTable().rows('.selected')
  if selected_rows.count() > 0
    complaint_ids = []
    for row, i in selected_rows[0]
      complaint_ids.push(selected_rows.data()[i].complaint_id)
    window.location = 'show_multiple?selected_ids=' + complaint_ids;
  else
    std_msg_error("alert",["There was an error. Please select an entry to edit"])

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
    image_content = '<img height=600 width=800 src="' + image + '"><span class="screenshot-button screenshot-reload-button esc-tooltipped" title="Reload Page">Reload Page</span>'
  else
    image_content = '<img height=600 width=800 src="' + image + '"><span class="screenshot-button screenshot-retake-button esc-tooltipped" id="se_id_' + id + '" title="Retake Screenshot"></span><span class="screenshot-button screenshot-close-button"></span>'

  $('#screenshot_id_'+ id).popover(
    html: true
    container: 'body'
    trigger: 'focus'
    template: '<div class="popover webcat-screenshot"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>'
    content: image_content).popover 'show'

window.lookup_prefix = () ->

  $('.lookup-drop-loader').removeClass('hidden')

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
      $('.lookup-drop-loader').addClass('hidden')
  )

window.retrieve_history = (position) ->
  $(".cat-url-error").hide()
  loader = $('.lookup-drop-loader')
  loader.removeClass('hidden')
  for url_position in [1..5]
    $("#url_#{url_position}").css("border-width", "")
    $("#url_#{url_position}").css("border-color", "")

  url = $("#url_" + position).val()

  if url.length > 0
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/categorize_urls_history'
      method: 'POST'
      data: {'position': position, url: url}
      success: (response) ->
        loader.addClass('hidden')
        json = JSON.parse(response)
        if json.error
          std_msg_error("<p>Something went wrong: #{json.error}","")
        else
          history_dialog_content =
              "<div class='cat-history-dialog dialog-content-wrapper'>
               <h4>#{url}</h4>
               <ul class='nav nav-tabs dialog-tabs' role='tablist'>
               <li class='nav-item active' role='presentation'>
                <a class='nav-link' role='tab' data-toggle='tab' href='#domain-history-tab' aria-controls='domain-history-tab'>
                   Domain History
                </a>
               </li>
               <li class='nav-item' role='presentation'>
                <a class='nav-link xbrs-history-tab' role='tab' data-toggle='tab' href='#xbrs-history-tab' aria-controls='xbrs-history-tab' onclick='get_xbrs_history(\"#{url}\", this)'>
                  XBRS History
                </a>
               </li>
               </ul>
                <div class='tab-pane active' role='tabpanel' id='domain-history-tab'>
                  <h5>Domain History</h5>
                  <table class='history-table'>
                    <thead>
                       <tr>
                        <th>Action</th>
                        <th>Confidence</th>
                        <th>Description</th>
                        <th>Time</th>
                        <th>User</th>
                        <th>Category</th>
                       </tr>
                    </thead>
                    <tbody>"
          for entry in json
            { action, confidence, description, time, user, category } = entry
            entry_string =
              "<tr>
                <td> #{action}</td>
                <td> #{confidence}</td>
                <td> #{description}</td>
                <td> #{time} </td>
                <td> #{user}</td>
                <td> #{category.descr}</td>
               </tr>"

            history_dialog_content += entry_string

          history_dialog_content +=
            "</tbody></table>
             </div>
             <div class='tab-pane' role='tabpanel' id='xbrs-history-tab'>
                <h5>XBRS History</h5>
                <table class='history-table xbrs-history-table' id='webcat-xbrs-history'></table>
             </div>"

          if $("history_dialog").length
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
            $('dialog_tabs').tabs();

      error: (response) ->
        $("#cat-url-error-message-#{position}").text("No history associated with this url.")
        loader.addClass('hidden')
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

  $('.lookup-drop-loader').removeClass('hidden')

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
      $('.lookup-drop-loader').addClass('hidden')
    error: (response) ->
      $('.lookup-drop-loader').addClass('hidden')
      std_msg_error("<p>There has been an error dropping categories: #{json.error}","")
)

window.fill_qual_subdomain =(anchor_tag, input_id, qual_subdomain) ->
  event.preventDefault();
  $('#' + input_id)[0].value = qual_subdomain
  return false;


format = (complaint_entry_row) ->
  complaint_entry = complaint_entry_row.data()
  row_id = complaint_entry_row[0][0]
  missing_data = '<span class="missing-data">No Data</span>'
  uri = ''
  host = ''
  qual_subdomain = ''
  lookup_val = ''
  url = ''
  search_uri = ''
  if complaint_entry.uri
    host = complaint_entry.uri
    url = host
    uri = '<a href="http://' + complaint_entry.uri + '"  target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + complaint_entry.uri + '</a>'
    uri_no_path = complaint_entry.uri
    qual_subdomain = complaint_entry.domain
    lookup_val = complaint_entry.domain
    if uri_no_path.indexOf('/') > 0
      uri_no_path = uri_no_path.split('/')[0] # strip out the path in a uri for Site Search, it's extraneous
    search_uri = '<a href="https://www.google.com/search?q=site%3A' + uri_no_path + '" target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + uri_no_path + '</a>'
  else if complaint_entry.domain
    if complaint_entry.subdomain
      host = complaint_entry.subdomain + '.'
    host = host + complaint_entry.domain
    url = host
    if complaint_entry.path
      url = host
    uri = '<a href="http://' + url + '" target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + url + '</a>'
    search_uri = '<a href="https://www.google.com/search?q=site%3A' + url + '" target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + url + '</a>'
    lookup_val = complaint_entry.domain
  else if  complaint_entry.ip_address
    host = complaint_entry.ip_address
    url = host
    lookup_val = complaint_entry.ip_address
    uri = '<a href="http://' + complaint_entry.ip_address + '"  target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + complaint_entry.ip_address + '</a>'
    search_uri = '<a href="https://www.google.com/search?q=site%3A' + complaint_entry.ip_address + '" target="_blank" onclick="select_cat_text_field(' + complaint_entry.entry_id + ')">' + complaint_entry.ip_address + '</a>'
  else
    uri = missing_data
  if complaint_entry.subdomain
    qual_subdomain = complaint_entry.subdomain + '.' + qual_subdomain
    lookup_val = complaint_entry.subdomain + '.' + qual_subdomain

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
      row_id = JSON.parse(this.data).id
      { current_category_data : current_categories, master_categories, sds_category, sds_domain_category} = JSON.parse(response)

      sds_category == '' unless sds_category != null

      master_categories_list = '#main-domain-categories_' + complaint_entry.entry_id

      if master_categories && master_categories.length > 0
        $(master_categories_list).closest('.domain-categories').show()
        for cat in master_categories
          new_cat = '<li>' + cat + '</li>'
          $(master_categories_list).append(new_cat)

      $(".simple-nested-table#entry-table-#{complaint_entry.entry_id} tbody > tr").remove()
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
            category_row = '<tr><td>' + confidence + '</td><td>' + mnemonic + ' - ' + name + '</td><td><span class="certainty-flag nested-tooltipped" onmouseover="triggerTooltips(this)" data-tooltip-content="#certainty_table' + complaint_entry.entry_id + '_' + cat_id + '">' + top_certainty + '</span>' + tooltip_all + '</td><td class=sds_category>' + sds_category + '</td><td class=sds_category>' + sds_domain_category + '</td></tr>'
            $(".simple-nested-table" + "#entry-table-" + complaint_entry.entry_id).append(category_row)
          else
            category_row = '<tr><td>' + confidence + '</td><td>' + mnemonic + ' - ' + name + '</td><td><span class="certainty-flag nested-tooltipped" onmouseover="triggerTooltips(this)" data-tooltip-content="#certainty_table' + complaint_entry.entry_id + '_' + cat_id + '">' + top_certainty + '</span>' + tooltip_all + '</td></tr>'
            $(".simple-nested-table" + "#entry-table-" + complaint_entry.entry_id).append(category_row)

      if jQuery.isEmptyObject(current_categories) == true && sds_category
        category_row = '<tr><td><td></td><td></td><td class=sds_category>' + sds_category + '</td></tr>'
        $(".simple-nested-table" + "#entry-table-" + complaint_entry.entry_id).append(category_row)

    error: (response) ->
      current_categories = ''
  )

  if complaint_entry.entry_history?
    if complaint_entry.entry_history.complaint_history.length >= 1
      complaint_history = complaint_entry.entry_history.complaint_history
    else
      complaint_history = ''

  { entry_id, domain, complaint_id, ip_address } = complaint_entry
  whois_lookup = if ip_address then ip_address else domain
  complaint_entry_html = ''
  input_cat = 'input_cat_' + entry_id

  if complaint_entry.status == "PENDING"
    if complaint_entry.uri_as_categorized  == ""
      # if a subdomain string exists, prepend it to the domain
      if complaint_entry.subdomain.length > 0
        domain = complaint_entry.subdomain + "." + complaint_entry.domain
      else
        domain = complaint_entry.domain
    else
      domain = complaint_entry.uri_as_categorized
    # Wondering what the line above does? See here: https://jira.vrt.sourcefire.com/browse/WEB-5880

    complaint_table_row_html = '<table class="active_table"><tr class="pending"><td class="no_pad"><div class="row">'
    complaint_submission_html =
        '<input type="radio" name="resolution_review_' + entry_id + '" value="commit" > Commit <br/>' +
        '<input type="radio" name="resolution_review_' + entry_id + '" value="decline" checked="checked"> Decline <br />' +
        '<input type="radio" name="resolution_review_' + entry_id + '" value="ignore"> Ignore (Bulk change only)' +
        '<br/>' +
        '<button class="tertiary" onclick="updatePending(' + entry_id + ',' + row_id + ')"> Submit </button>' +
        '</div>'
  else
    complaint_table_row_html = '<table class="active_table"><tr class="active_master_submit" type="submit_changes" entry_id="' + entry_id + '"  row_id = "' + row_id + '"><td class="no_pad"><div class="row">'
    complaint_submission_html =
        '<input type="radio" class="resolution_radio_button" id="unchanged' + entry_id + '" name="resolution' + entry_id + '" value="UNCHANGED" ' + unchanged_radio + entry_status + '> Unchanged <br/> ' +
        '<input type="radio" class="resolution_radio_button" id="fixed' + entry_id + '" name="resolution' + entry_id + '" value="FIXED"  ' + fixed_radio + entry_status + '> Fixed  <br/> ' +
        '<input type="radio" class="resolution_radio_button" id="invalid' + entry_id + '" name="resolution' + entry_id + '" value="INVALID" ' + invalid_radio + entry_status + '> Invalid' +
        '<br/>' +
        '<button class="tertiary submit_changes ' + submit_class + '" id="submit_changes_' + entry_id + '" onclick="updateEntryColumns(' + entry_id + ',' + row_id + ')">Submit Changes</button>' +
        '<button class="tertiary ' + reopen_class + '" id="reopen_' + entry_id + '" onclick="reopenComplaint(' + entry_id + ', this)">Reopen Complaint</button>' +
        '</div>'

  retake_in_progress = false
  if complaint_entry.screen_shot_error == "Retaking screenshot please wait."
    retake_in_progress = true

  edit_input = if domain != "" then domain else host #if the domain is empty, then display host for ips in edit input

  if complaint_entry.complaint_source?
    if complaint_entry.complaint_source == 'talos-intelligence'
      complaint_source = 'TI Webform'
    else if complaint_entry.complaint_source == 'talos-intelligence-api'
      complaint_source = 'TI API'
    else if complaint_entry.complaint_source == ''
      complaint_source = '<span class="missing-data">Source unknown</span>'
    else
      complaint_source = complaint_entry.complaint_source
  else
    complaint_source = '<span class="missing-data">Source unknown</span>'

  form_change_item = domain || complaint_entry.ip_address

  complaint_entry_html =
      complaint_table_row_html +
      "<div class='col-xs-12 col-sm-8 nested-complaint-static-data'>" +
      "<div class='row'>" +
      "<div class='col-xs-3 col-with-divider'>" +
      "<div class='screenshot-thumb-wrapper'>" +
      "<img id='screenshot_id_#{entry_id}' class='screenshot-thumb-img' title='#{screen_shot_error}' data-toggle='popover' onclick='enlarge_image('#{entry_id} , complaint_entries/serve_image?complaint_entry_id='#{entry_id} , #{retake_in_progress}')' src='complaint_entries/serve_image?complaint_entry_id=#{entry_id}'/>" +
      "</div>" +
      "<div class='complaint-entry-info'>" +
      "<label class='content-label-sm'>Case ID</label>"+
      "<span class='nested-complaint-data case-id'><a href='complaints/#{complaint_id}'>#{complaint_id}</a></span>" +
      "<label class='content-label-sm'>Entry URI</label>" +
      "<span class='nested-complaint-data input-truncate esc-tooltipped' id='entry-uri-#{entry_id}' title='#{url}'><a href='http://#{url}' target='_blank'>#{url}</a></span>" +
      "<label class='content-label-sm' id='site-search'>Site Search</label>" +
      "<span class='nested-complaint-data input-truncate esc-tooltipped' id='site-search-#{entry_id}' title='#{url}'>#{search_uri}</span>" +
      "<label class='content-label-sm'>Customer Name</label>" +
      "<span class='nested-complaint-data'>#{customer_name}</span>" +
      "<label class='content-label-sm'>Customer Description</label>" +
      "<span class='nested-complaint-data'>#{customer_description}</span>" +
      "<label class='content-label-sm'>Complaint Source</label>" +
      "<span class='nested-complaint-data'>#{complaint_source}</span>" +
      "</div></div><div class='col-xs-7 col-with-divider'>" +
      '<table class="simple-nested-table" id="entry-table-' + entry_id + '"><thead><tr><th class="col-sm-1">Conf</th><th class="col-sm-3">WBRS Categories</th><th class="col-sm-2">WBRS Certainty</th><th class="col-sm-3">SDS URI Category</th><th class="col-sm-3">SDS Domain Category</th></tr></thead>' +
      '</table>' +
      '</br>' +
      '</div><div class="col-xs-2">' +
      '<button class="secondary" id="history-' + entry_id + '" onclick="history_dialog(' + entry_id  + ',\'' + url + '\')">History</button><br/>' +
      '<button class="secondary" id="domain-' + entry_id + '" onclick="WebCat.RepLookup.whoIsLookups(\'' + whois_lookup + '\')">Whois</domain>' +
      '</div></div>' +
      '</div><div class="col-xs-12 col-sm-4 nested-complaint-editable-data">' +
      '<div class="row">' +
      '<div class="col-xs-12">' +
      '<div><label class="content-label-sm">Original</label></div> ' +
      '<div>' + host  + '</div>' +
      '<label class="content-label-sm">Edit URI</label><br/>' +
      '<input class="nested-table-input complaint-uri-input" id="complaint_prefix_' + entry_id +
      '" type="text" data-domain="' + form_change_item + '" data-qual_subdomain="'+ qual_subdomain + '" value="' + edit_input +
      '"' + entry_status + '>' +
      '<button class="secondary inline-button" onclick="updateURI(event,' + entry_id + ')">Update URI</button><br/>' +
      '<div><a href="#" onclick="fill_qual_subdomain(this, \'complaint_prefix_' + entry_id + '\', \''+ qual_subdomain + '\')">subdomain</a></div>' +
      '<div class="complaint-selectize-col-wrapper">' +
      '<label class="content-label-sm">Edit Categories / Confidence Order</label>' +
      '<select id="' + input_cat + '" name="[' + input_cat + '][]" class="' + status_class + '" placeholder="Enter up to 5 categories" value="" onchange="touchedFormChange(\'' + form_change_item + '\')"></select>' +
      '</div>' +
      '<div class="domain-categories" >' +
      '<label class="content-label-sm">Inherit Categories From Main Domain</label><br/>' +
      '<ul id="main-domain-categories_' + entry_id + '"></ul>'+
      '<button class="secondary inline-button" onclick="inheritCategories(' + entry_id + ')">Inherit</button><br/>' +
      '</div>' +'</div><div class="col-xs-8">' +
      '<label class="content-label-sm">Internal Comment</label><br/>' +
      '<input class="nested-table-input complaint-comment-input" id="complaint_comment_' + entry_id + '" type="text" data-domain="' + domain + '" class="nested-table-input" value="' + internal_comment + '" placeholder="Add a comment." ' + entry_status + '><br/>'  +
      '<label class="content-label-sm customer-label">Customer Facing Comment</label><br/>' +
      '<input class="nested-table-input complaint-comment-input" id="complaint_resolution_comment_' + entry_id + '" type="text" data-domain="' + domain + '" value="' + resolution_comment + '" placeholder="Add a comment for the customer." ' + entry_status + '>' +
      '</div>' +
      '<div class="col-xs-4">' +
      '<label class="content-label-sm">Resolution</label><br/>' +
      complaint_submission_html +
      '</div></div></div></div></td></tr></table>'

  complaint_entry_html


## Complaint history dialog box. Includes tabs for domain history, complaint entry history, and xbrs history of the url.
window.history_dialog = (id, url) ->

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/history'
    method: 'POST'
    headers: headers
    data: {'id': id}
    success: (response) ->
      json = $.parseJSON(response)
      if json.error
        alert(json.error)
      else
        history_dialog_content =
          "<div class='cat-history-dialog dialog-content-wrapper'>
               <h4>#{url}</h4>
              <ul class='nav nav-tabs dialog-tabs' role='tablist'>
               <li class='nav-item active' role='presentation'>
                <a class='nav-link' role='tab' data-toggle='tab' href='#domain-history-tab' aria-controls='domain-history-tab'>
                   Domain History
                </a>
               </li>
              <li class='nav-item' role='presentation'>
                <a class='nav-link' role='tab' data-toggle='tab' href='#complaint-history-tab' aria-controls='complaint-history-tab'>
                   Complaint Entry History
                </a>
              </li>
               <li class='nav-item' role='presentation'>
                <a class='nav-link' role='tab' data-toggle='tab' href='#xbrs-history-tab' aria-controls='xbrs-history-tab' onclick='get_xbrs_history(\"#{url}\", this)'>
                  XBRS Timeline
                </a>
               </li>
            </ul>
            <div class='tab-pane active' role='tabpanel' id='domain-history-tab'>
            <h5>Domain History</h5>"

        if json.entry_history.domain_history.length < 1
          history_dialog_content += '<span class="missing-data">No domain history available.</span>'
        else
          history_dialog_content +=
            '<table class="history-table"><thead><tr><th>Action</th><th>Confidence</th><th>Description</th><th>Time</th><th>User</th><th>Category</th></tr></thead>' +
              '<tbody>'
          # Build domain history table
          for entry in json.entry_history.domain_history
            history_dialog_content +=
              '<tr>' +
                '<td>' + entry['action'] + '</td>' +
                '<td>' + entry['confidence'] + '</td>' +
                '<td>' + entry['description'] + '</td>' +
                '<td>' + entry['time'] + '</td>' +
                '<td>' + entry['user'] + '</td>' +
                '<td>' + entry['category']['descr'] + '</td>' +
                '</tr>'
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
          # End complaint history table
          history_dialog_content += '</tbody></table></div>'


        # End complaint history table tab
        # Start XBRS Tab
        history_dialog_content +=
          "
           <div class='tab-pane' role='tabpanel' id='xbrs-history-tab'>
            <h5>XBRS Timeline</h5>
              <table class=''history-table xbrs-history-table' id='webcat-xbrs-history'></table>
            </div>
           "

        # Only one history dialog open at a time - content gets swapped out
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
            minWidth: 800
            position: { my: "right top", at: "right top", of: window }
          $('#history_dialog').dialog('open')
    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)


## Fetches XBRS history of a url on click of the XBRS tab in history
window.get_xbrs_history = (url, tab) ->
  wrapper = $(tab).parents('.dialog-content-wrapper')[0]
  xbrs_table = $("#webcat-xbrs-history")
  xbrs_msg = $(wrapper).find('.xbrs-no-data-msg')[0]
  # Clear table of residual data
  $(xbrs_table).empty()
  if xbrs_msg?
    $(xbrs_msg).remove()
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/xbrs'
    method: 'POST'
    headers: headers
    data: {'url': url}
    success: (response) ->
      if response.data.length < 1
        $('<span class="missing-data xbrs-no-data-msg">No XBRS history available.</span>').insertBefore(xbrs_table)
      else


        $(xbrs_table).append(document.createElement('thead'))
        $(xbrs_table).append(document.createElement('tbody'))
        thead = $(xbrs_table).find('thead')
        tbody = $(xbrs_table).find('tbody')
        table_headers = ['Timestamp', 'Scrore', 'V2 Content Cat', 'V3 Content Cats', 'Threat Cats', 'Rule Hits']

        parsed_rows = []
        thead_row = ''

        table_headers.forEach (header)->
          thead_row += "<th> #{header}</th>"
        thead.append(thead_row)

        response.data.forEach (row)->
          data_row = ""

          for key, value of row
            data_row += "<td>#{value || '-'}</td>"

          tbody.append("<tr>#{data_row}</tr>")

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

## This is for expanding and collapsing the nested rows ##
window.click_table_buttons = (complaint_table, button)->
  tr = $(button).closest('tr')
  row = complaint_table.row(tr)

  if row.child.isShown()       # This row is already open - close it
    row.child.hide()
    tr.removeClass 'shown'
    tr.addClass 'not-shown'

    if verifyMasterSubmit() == false
      $('#master-submit').prop('disabled', true)

  else
    # Open this row
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: "/escalations/api/v1/escalations/webcat/complaints/category_list"
      method: 'GET'
      headers: headers
      success: (response) ->
        data = row.data()
        cat_select = '#input_cat_'+ data.entry_id

        webcat_options = []
        for key, value of response
          cat_code = key.split(' - ')[1]
          value_name = key.split(' - ')[0]
          webcat_options.push({category_id: value, category_name: value_name, category_code: cat_code})

        category_ids = []
        for name in selected_options(data.category)
          for x, y of response
            value_name = x.split(' - ')[0]
            if name.trim() == value_name
              category_ids.push(y)

        row.child(format(row)).show()
        nested_tooltip()

        tr.removeClass 'not-shown'
        tr.addClass 'shown'
        td = $(tr).next('tr').find('td:first')
        unless $(td).hasClass 'nested-complaint-data-wrapper'
          $(td).addClass 'nested-complaint-data-wrapper'
        if ['NEW','ASSIGNED','PENDING', 'REOPENED', 'ACTIVE'].includes(data.status)
          $( cat_select ).selectize {
            persist: true,
            create: false,
            maxItems: 5,
            closeAfterSelect: true,
            valueField: 'category_id',
            labelField: 'category_name',
            searchField: ['category_name', 'category_code'],
            options: webcat_options,
            items: category_ids,
            onItemAdd: ->
              if verifyMasterSubmit() == true
                $('#master-submit').prop('disabled', false)
            onItemRemove: ->
              if verifyMasterSubmit() == true
                $('#master-submit').prop('disabled', false)
              else
                $('#master-submit').prop('disabled', true)
            score: (input) ->
              #  Adding some customization for autofill
              #  restricting on certain cats to avoid accidental categorization
              #  (replaces selectize's built-in `getScoreFunction()` with our own)
              (item) ->
                if item.category_code == 'cprn' || item.category_code == 'xpol' || item.category_code == 'xita' || item.category_code == 'xgbr' || item.category_code == 'xdeu' || item.category_code == 'piah'
                  item.category_code == input ? 1 : 0
                else if item.category_name.toLowerCase().startsWith(input.toLowerCase())
                  1
                else if item.category_name.toLowerCase().includes(input.toLowerCase()) || item.category_code.toLowerCase().includes(input.toLowerCase())
                  0.9
                else
                  0
          }
        else
          # need to initialize the selectize function but disable it here if entry is completed
          $completed_selectize = $( cat_select ).selectize {
            persist: true,
            create: false,
            maxItems: 5,
            closeAfterSelect: true,
            valueField: 'category_id',
            labelField: 'category_name',
            searchField: ['category_name', 'category_code'],
            options: webcat_options,
            items: category_ids,
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
      error: (response) ->
        std_msg_error("<p>Something went wrong</p>","")
    , this)

window.display_preview_window = (entry) ->
  {domain, category, id} = entry
  $('#complaint_id_x_prefix')[0].value = domain
  $('#complaint_id_x_categories')[0].value = category
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  #when checkbox is clicked take the domain and path and try to open it in the iframe
  path = ""
  subdomain = ""
  if entry.subdomain
    subdomain = entry.subdomain + "."
  if entry.path
    path = entry.path
  loc = "http://" + subdomain + domain + path
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
  $("#complaint_entry_row_"+ id ).addClass("complaint_selected")
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
  for row in selectedRows
    if expand
      if !$(row).hasClass('shown')
        $(row).find('.expand-row-button-inline').click()
    else
      if $(row).hasClass('shown')
        $(row).find('.expand-row-button-inline').click()
        $(row).addClass('selected')
  $(selectState).addClass('selected')

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

processSubmitMaster = () ->
  data = []
  selectedEntryDomains = (sessionStorage.getItem("touchedForm")|| "" )
  return if selectedEntryDomains.length == 0

  # remove empty values
  selectedEntryDomains = selectedEntryDomains.split(',').filter((item) -> item);
  selectedEntries = []
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
        data.push({entry_id: entry_id, error: false, row_id: row_id, prefix: prefix, categories: categories, category_names: category_names, status: status, comment: comment, resolution_comment: resolution_comment, uri_as_categorized: uri_as_categorized})
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

    error: (response) ->
      std_msg_error("Unable to submit changes for selected entries.","", reload: false)

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


window.verifyMasterSubmit = () ->
  boolean = false
  if $('.shown').length > 0 && $('.has-items').length > 0
    $('.has-items').each ->
      if (!$(this).closest('tr').hasClass("pending"))
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
    id = this.name.split("resolution")[1]
    domain = $("#complaint_prefix_"+id)[0].dataset.domain
    touchedFormChange(domain)
    $('#master-submit').prop('disabled', false)

  $('.expand-all').click ->
    complaint_table = $('#complaints-index').DataTable()
    td = $('#complaints-index').find('td.expandable-row-column')

    td.each ->
      tr = $(this).closest('tr')
      row = complaint_table.row(tr)

      unless row.child.isShown()

        row.child(format(row)).show()
        nested_tooltip()

        tr.addClass 'shown'

        td = $(tr).next('tr').find('td:first')
        $(td).addClass 'nested-complaint-data-wrapper'
        unless $(td).hasClass 'nested-complaint-data-wrapper'
          tr.find('td:first').addClass 'nested-complaint-data-wrapper'

        cat_select = '#input_cat_'+ row.data().entry_id
        $(cat_select).selectize {
          persist: false,
          create: false,
          maxItems: 5,
          closeAfterSelect: true,
          valueField: 'category_id',
          labelField: 'category_name',
          searchField: ['category_name', 'category_code'],
          options: AC.WebCat.createSelectOptions('#input_cat_'+ row.data().entry_id)
          items: AC.WebCat.getCategoryIds(selected_options(row.data().category), cat_select)
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


  $('#complaint_ticket_status').click ->
    selected_rows = $('#complaints-index').DataTable().rows('.selected')
    if (selected_rows[0].length > 0)
      $('.ticket-status-radio-label').click ->
        $('#loader-modal').modal()
        radio_button = $(this).prev('.ticket-status-radio')
        $(radio_button[0]).trigger('click')
        entry_ids = []
        for row, i in selected_rows[0]
          entry_ids.push(selected_rows.data()[i].entry_id)
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

# Convert webcat to webrep
# Enable / disable button to attempt based on if anything is selected
$(document).on 'click', '#complaints-index tr, #complaints_check_box, #complaints_select_all', ->
  if $('tr.selected').length == 1
    $('#convert-ticket-button').removeAttr('disabled')
  else
    $('#convert-ticket-button').attr('disabled', 'disabled')


# Prepare ticket for converting
window.prep_complaint_to_convert = () ->
  if $('tr.selected').length > 1
    # This shouldn't happen, but just in case
    std_api_error('Can only convert 1 complaint at a time.')
  else
    # get all data associated with the selected row
    complaint_row = $('tr.selected')[0]
    row_data = $('#complaints-index').DataTable().row(complaint_row).data()

    complaint_id = row_data.complaint_id
    summary = row_data.description
    entries_table = $('#entries-to-convert tbody')
    entry_id = row_data.entry_id

    # clear residual info from prev selections
    $('#complaint-id-to-convert').empty()
    $('.convert-entry-count').empty()
    $(entries_table).empty()
    $('#convert-ticket-summary').empty()
    $('#convert-to-webrep').attr('disabled', 'disabled')

    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webcat/complaints/view_complaint'
      data:
        complaint_entry_id: entry_id
      success: (response) ->
        response = $.parseJSON(response)
        entries = response.data.complaint_entries
        entry_count = entries.length

        # now that we have parent data, check complaint status & source
        complaint_status = response.data.complaint.status
        complaint_source = response.data.complaint.ticket_source

        if complaint_source == 'talos-intelligence' || complaint_source == 'talos-intelligence-api'
          if complaint_status == 'NEW' || complaint_status == 'ACTIVE' || complaint_status == 'REOPENED'
            # populate the dropdown
            $('#complaint-id-to-convert').text(complaint_id)
            $('.convert-entry-count').text('(' + entry_count + ')')

            # extra handling to deal with too many entries and overlapping issues with selectize
            if entry_count > 8
              $('.convert-entry-table-wrapper').addClass('max-scroll')
            else
              $('.convert-entry-table-wrapper').removeClass('max-scroll')

            $(entries).each ->
              if this.entry_type == 'IP'
                entry_content = this.ip_address
              else
                entry_content = this.uri

              entry_row = '<tr><td>' + this.id + '</td><td class="entry-content-to-convert">' + entry_content + '</td>' +
                '<td class="text-center entry-disposition">' +
                '<div class="inline-radio-wrapper"><label for="' + this.id + '-fp-radio">FP</label><input type="radio" class="disposition-radio" name="disposition-' + this.id + '" value="fp" id="' + this.id + '-fp-radio"/></div>' +
                '<div class="inline-radio-wrapper"><label for="' + this.id + '-fn-radio">FN</label><input type="radio" class="disposition-radio" name="disposition-' + this.id + '" value="fn" id="' + this.id + '-fn-radio"/></div>' +
                '</td></tr>'

              $(entries_table).append(entry_row)

            $('#convert-ticket-summary').append(summary)

          else
            std_msg_error('Ticket cannot be converted', ['Selected entry\'s parent ticket is not in a convertible (open) status.'])
            return

        else
          std_msg_error('Ticket cannot be converted', ['Selected ticket is not a customer ticket from talos-intelligence.'])
          return

      error: (response) ->
        console.log response
        std_msg_error('Error preparing ticket for conversion', [response])
    )

window.nested_tooltip = () ->
  $('.esc-tooltipped:not(.tooltipstered)').tooltipster
    theme: [
      'tooltipster-borderless'
      'tooltipster-borderless-customized'
    ]
convert_complaint_to_webrep = () ->
  # get the parent ticket info
  complaint_id = parseInt($('#complaint-id-to-convert').text())
  summary = $('#convert-ticket-summary').val()
  submission_type = $('input[name=ticket-type]:checked').val()

  # get the entries
  suggested_dispositions = []
  entry_rows = $('#entries-to-convert tbody tr')
  $(entry_rows).each ->
    entry_content = $(this).find('.entry-content-to-convert').text()
    disp_radio_name = $(this).find('input[type=radio]').attr('name')
    entry_disposition = $(this).find('input[name=' + disp_radio_name + ']:checked').val()
    suggested_dispositions.push(entry: entry_content, suggested_disposition: entry_disposition)

  std_msg_ajax(
    method: 'POST'
    url: '/escalations/api/v1/escalations/webcat/complaints/convert_ticket'
    data: {
      complaint_id: complaint_id
      summary: summary
      submission_type: submission_type
      suggested_dispositions: suggested_dispositions
    }
    success: (response) ->
      console.log response
      std_msg_success('Success',["Complaint converted to Reputation Dispute."], reload: true)
    error: (response) ->
      std_msg_error('Error converting ticket', ['Complaint unable to be converted to Reputation Dispute.'], reload: false)
  )


$ ->
  # check prior to enabling submit convert to webrep button
  $('#convert-ticket-dropdown').click ->
    # find all the radios
    radios = $(this).find('input:radio')
    # separate into groups by name & then grab only the unique names
    radio_names = []
    $(radios).each ->
      group = $(this).attr('name')
      radio_names.push(group)
    radio_groups = Array.from(new Set(radio_names))

    # make sure each radio group has something checked
    allchecked = 0
    $(radio_groups).each ->
      val = $('input[name=' + this + ']:checked').val()
      unless (val == undefined) || (val == null)
        allchecked++

    if allchecked == radio_groups.length
      $('#convert-to-webrep').removeAttr('disabled')
    else
      $('#convert-to-webrep').attr('disabled', 'disabled')




  $('#convert-to-webrep').click ->
    convert_complaint_to_webrep()

  $('#wbnp-full-report').dialog
    autoOpen: false
    width: 700
    minHeight: 300
    position:
      my: "right top"
      at: "right top+150"
      of: window


  $('#wbnp-report-button').click ->
    $('#wbnp-full-report').dialog('open')

