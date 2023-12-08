### FUNCTIONS FOR MOTHRA - JIRA TICKET IMPORTS ###
$ ->
  if window.location.pathname == '/escalations/webcat/reports'
    build_imports_table()


window.change_ticket_view = (type,button) ->
  if $(button).hasClass('active-view')
    #if view is already active, do nothing
    return
  else

    checked = $('.imports_check_box:checked')
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
        $('.reports-toolbar .toolbar-button').attr('disabled', true)
        $('.imports-url-checkbox').prop('checked', false)
    # show/hide appropriate elements
    $('#webcat-imports-index_wrapper, .webcat-ticket-view').toggleClass('hidden')
    $('.list-button, .view-tickets').toggleClass('active-view')

window.build_single_row = (rd, data) ->
  { urls } = data
  { issue_key, submitter, status, result, imported_at, issue_status, issue_platform, issue_description, issue_summary} = rd


  status = status.toUpperCase()
  if result && status != result.toUpperCase()
    status = "#{status} | #{result}"

  # build upper data
  # breaking out layout html for more granular control over display
  ticket_html = "<div class='row ticket-rows vis-ticket' id='#{issue_key}'>" +
                  "<div class='col-xs-12'>" +
                    "<h4 class='ticket-report-header'>Jira Ticket Information</h4>" +
                    "<div class='row'>" +
                      "<div class='col-md-6 col-sm-8 col-xs-12'>" +
                        "<div class='row'>" +
                          "<div class='col-xs-3'>" +
                            "<label class='content-label-sm'>Ticket ID</label>" +
                            "<div class='jira-ticket-id top-info-data'>#{issue_key}</div>" +
                          "</div>" +
                          "<div class='col-xs-9'>" +
                            "<label class='content-label-sm'>Summary</label>" +
                            "<div class='data-report-content top-info-data'>#{issue_summary}</div>" +
                          "</div>" +
                        "</div>" +
                        "<div class='row'>" +
                          "<div class='col-xs-12'>" +
                            "<label class='content-label-sm'>Description</label>" +
                            "<div class='data-report-content top-info-data'>#{issue_description}</div>" +
                          "</div>" +
                        "</div>" +
                      "</div>" +
                      "<div class='col-md-6 col-sm-4 col-xs-12'>" +
                        "<div class='row'>" +
                          "<div class='col-xs-6'>" +
                            "<label class='content-label-sm'>Imported On</label>" +
                            "<div class='data-report-content top-info-data'>#{imported_at}</div>" +
                            "<label class='content-label-sm'>Import Status</label>" +
                            "<div class='data-report-content top-info-data'>#{status}</div>" +
                          "</div>" +
                          "<div class='col-xs-6'>" +
                            "<label class='content-label-sm'>Ticket Status</label>" +
                            "<div class='data-report-content top-info-data'>#{issue_status}</div>" +
                            "<label class='content-label-sm'>Submitter</label>" +
                            "<div class='data-report-content top-info-data'>#{submitter}</div>" +
                          "</div>" +
                        "</div>" +
                      "</div>" +
                    "</div>"

  if urls.length
    ticket_html += "<div class='row'><div class='col-xs-12 urls-container'>
                    <label class='data-report-label'>Urls Imported from Ticket</label>"

    #build table data
    ticket_html +="<table class='table responsive dataTable no-footer url-datatable' id='#{issue_key}-datatable' role='datatable'>
                    <thead>
                    <tr>
                      <th><input type='checkbox' name='cbox' class='imports-url-checkbox-bulk' id='cbox-#{issue_key}-urls' value='#{issue_key}'/></th>
                      <th></th>
                      <th>Original</th>
                      <th>Sanitized Domain</th>
                      <th>Entry ID</th>
                      <th>Case ID</th>
                      <th>Status</th>
                      <th>Resolution</th>
                      <th>Resolution Time</th>
                      <th>Category</th>
                      <th>Assignee</th>
                      <th>Age</th>
                      <th>Bast Response</th>
                    </tr>
                  </thead>
                  </table>
                  </div>
                  </div>
                  <hr/>
                  </div>
                  </div>"


    $('.webcat-ticket-view').append(ticket_html)

    # dynamic datatable for each selected jira import report
    # handled differently than
    $("##{issue_key}-datatable").DataTable(
        data:urls
        searching: false
        order: [[2,'asc',]]
        lengthMenu: [25, 50, 100]
        dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
        columnDefs:
          [{
            targets: [ 0,1 ]
            orderable: false
            searchable: false
          }
          {
            targets: [ 0 ]
            className:'checkbox-cell'
          }
          {
            targets: [ 10 ]
            className:'entry-assignee'
          }]
        drawCallback:()->
          init_tooltip()  #initialize tooltip after table is drawn and html exists (this is just for important tags at the moment)

        createdRow: (row, data, index) ->
            url =          data[2]
            entry_id =     data[4]
            complaint_id = data[5]
            status =       data[6]
            age =          data[11]
            is_important = data[1]

            checkbox = "<input type='checkbox' name='cbox' class='imports-url-checkbox imports-url-checkbox-#{issue_key}'  id='cbox-#{issue_key}-#{index}-urls' value='#{entry_id}'/>"
            $('td', row).eq(0).html(checkbox)

            if is_important
              $('td', row).eq(1).html('<span class="entry-important-flag esc-tooltipped is-important highlight-second-review" tooltip title="Important"></span>')

            if url
              updated_url = "<span class='jira-url esc-tooltipped' title='#{url}'>#{url}</span>"
              $('td', row).eq(2).html(updated_url)

            if complaint_id
              complaint_link = "<a target='_blank' class='ticket-id' href='/escalations/webcat/complaints/#{complaint_id}'>#{complaint_id}<a>"
              $('td', row).eq(5).html(complaint_link)

            if age
              unless status == 'COMPLETED' || status == 'RESOLVED'
                if age.indexOf('h') != -1 && age.indexOf('h') >= 3
                  hour = parseInt( age.split("h")[0] )
                  if hour>= 3 && hour < 12
                    age_class = 'ticket-age-over3hr'
                  else if hour >= 12
                    age_class = 'ticket-age-over12hr'
                else if age.indexOf('mo') != -1
                  age_class = 'ticket-age-over12hr'
                else if (age.indexOf('m') != -1) || (age.indexOf('s') != -1)
                  age_class = ''
                else
                  age_class = 'ticket-age-over12hr'
                $('td', row).eq(11).html("<span class='#{age_class}'>#{age}</span>")

        )
  else
    ticket_html += "<hr/></div>"
    $('.webcat-ticket-view').append(ticket_html)

window.build_ticket_view = (checked, view) ->
  table =  $('#webcat-imports-index').DataTable()

  if view == 'single'
    checked = [checked]

  for check, index in checked
    if index == 10
      break
    else
      row = $(check).closest('tr')
      id = $(check).attr('value')
      el = $("##{id}")

      if el.length > 0
        # if we have already built this ticket view, show it
        el.removeClass('hidden')
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
  all_rows = $("#webcat-imports-index tbody tr").filter(':visible')
  $('.imports_check_box:visible').prop('checked', checked)
  $('.imports_check_box:visible').trigger('change')
  if checked
    all_rows.addClass('selected')
  else
    all_rows.removeClass('selected')

$(document).on 'click', '.imports-url-checkbox-bulk',->
  checked = $(this).prop('checked')
  issue_key = $(this).val()
  $(".imports-url-checkbox-#{issue_key}").prop('checked', checked)
  $(".imports-url-checkbox-#{issue_key}").trigger("change")

$(document).on 'change', '.imports-url-checkbox',->

  checked_rows = $(".imports-url-checkbox:checked").closest('tr')
  current_username = $('input[name="current_user_name"]').val()
  can_take =     false
  can_return =   false
  can_assign =   false
  can_unassign = false

  for row in checked_rows
    user = $(row).find('.entry-assignee').text()

    if user != ''                       then can_assign = true
    if user == current_username         then can_return = true
    if user == 'vrtincom'               then can_take = true
    if user != '' && user != 'vrtincom' then can_unassign = true

  if can_take
    $('.take-ticket-toolbar-button').removeAttr('disabled')
  else
    $('.take-ticket-toolbar-button').attr('disabled', true)

  if can_return
    $('.return-ticket-toolbar-button').removeAttr('disabled')
  else
    $('.return-ticket-toolbar-button').attr('disabled', true)

  if can_assign
    $(".ticket-owner-button").removeAttr('disabled')
  else
    $(".ticket-owner-button").attr('disabled', true)

  if can_unassign
    $(".remove-assignee-toolbar-button").removeAttr('disabled')
  else
    $(".remove-assignee-toolbar-button").attr('disabled', true)

$(document).on 'click', '.imports_check_box',->
  row = $(this).closest('tr')
  check = $('.imports_check_box')

  if check.prop('checked')
    row.addClass('selected')
  else
    row.removeClass('selected')

  num_checked = $('.imports_check_box:checked').length
  if num_checked == check.length
    check.prop('checked', true)
  if num_checked == 0
    check.prop('checked', false)

$(document).on 'change', '.imports_check_box', ->
  retry_button = $('.toolbar-button.retry-button')
  resolve_button = $('.toolbar-button.close-ticket-button')
  can_retry = false
  can_resolve = false
  checked_data = checked_row_data() || [];

  if checked_data.length > 0
    $('.close-ticket-button').removeAttr('disabled')
  else
    $('.close-ticket-button').attr('disabled', true)

  checked_data.each ->
    if this.status == 'Failure'
      can_retry = true
    if this.issue_status != 'Resolved'
      can_resolve = true

  if can_retry
    retry_button.removeAttr('disabled')
  else
    retry_button.attr('disabled', true)

  if can_resolve
    resolve_button.removeAttr('disabled')
  else
    resolve_button.attr('disabled', true)

$(document).on 'click', '#show-failed, #show-complete, #show-pending',->
  show_failed = $('#show-failed').prop('checked')
  show_complete = $('#show-complete').prop('checked')
  show_pending = $('#show-pending').prop('checked')

  if show_pending
    $('.pending').show()
  else
    $('.pending').hide()

  if show_complete
    $('.complete').show()
  else
    $('.complete').hide()

  if show_failed
    $('.failure').show()
  else
    $('.failure').hide()

window.checked_row_data = ()->
  table = $('#webcat-imports-index').DataTable()
  rows = $('.imports_check_box:checked').closest('tr')
  data = table.rows(rows).data()
  return data

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

window.run_imports = () ->
  std_msg_ajax(
    method: 'get'
    url: '/escalations/api/v1/escalations/jira_import_tasks/queue_imports'
    success: (response) ->
      std_msg_success('Import Successful', [], reload: false)
      $('#webcat-imports-index').DataTable().ajax.reload()
    error: (response) ->
      std_api_error(response, 'Error running manual import.', reload: false)
  )
window.close_related_issues = () ->
  ids = []
  checked_row_data().map( (r) ->
    # only run ids if the row is not resolved
    if r.issue_status != "Resolved"
      ids.push(parseInt(r.id))
  )
  if ids.length
    std_msg_ajax
      method: 'put'
      url: '/escalations/api/v1/escalations/jira_import_tasks/close_related_issues'
      data: task_ids: ids
      success: (response) ->
        std_msg_success('Successfully closed Jira issues',[], reload: false)
        $('.toolbar-button.close-ticket-button').attr('disabled', true)
        setTimeout ->
          # on success, wait a moment then reload data to reflect any status changes
          $('#webcat-imports-index').DataTable().ajax.reload()
        , 500
      error: (response) ->
        console.log response
        std_api_error(response, 'Error closing Jira issues', reload: false)
  else
    std_msg_error('Select at least one unresolved Jira issue.')

window.build_imports_table = () ->
  $('#webcat-imports-index').DataTable(
    serverSide: true
    ajax: "/escalations/webcat/jira_import_tasks.json"
    order:[[1, 'desc']]
    dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
    language: {
      search: "_INPUT_"
      searchPlaceholder: "Search within table"
    }
    initComplete: (data,type,full,meta) ->
      $('#webcat-imports-index_filter input').addClass('table-search-input');
    columnDefs: [
      {
        targets: [ 0,4 ]
        orderable: false
        searchable: false
      }
      {
        targets: [ 0,1,2,3,4,5,6 ]
        defaultContent:'-'
      }
    ]
    createdRow:(row, data, dataIndex) ->
      {status} = data
      $(row).addClass(status.toLowerCase())

    columns:[
      {
        data:'issue_key',
        className: 'checkbox-cell',
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
        className:'result-col'
        width:'150px'
        render: (data,type,full,meta) ->
          {status, result, id}=full

          html = "<div class='result-container'>"

          if result && result != status
            html += "<div>
                      <div class='jira-status'>#{status}</div>
                      <div class='jira-result-note'>#{result}</div>
                     </div>"
          else
            html = "<span class='jira-status'>#{status}</span>"

          if status == 'Failure'
            html += "<div>
                  <button class='inline-retry-button retry-button tooltipped tooltipstered' title='Retry' onclick='retry_imports(#{id})'></button>
                 </div>"

          html += "</div>"

      },
      {
        data: 'issue_status'
        orderable: true
      },
      {
        data: 'status'
        visible: false
      }
    ]
  )

window.jira_assignee_hub = (type) ->
  # handle all assigning for jira import entries
  selected = $('.imports-url-checkbox:checked')
  entry_ids = []
  selected_rows = []
  for entry in selected
    val = $(entry).val()
    if val && val != 'null'
      entry_ids.push(val)
      selected_rows.push( $(entry).closest('tr') )

  if entry_ids.length > 0
    data = {'complaint_entry_ids': entry_ids}
    url = "/escalations/api/v1/escalations/webcat/complaint_entries/#{type}"
    err_msg = "Something Went Wrong:"
    succ_msg = "Entries successfully assigned"

    switch type
      when 'change_assignee'
        data['user_id'] = $('#index_target_assignee option:selected').val()
        err_msg = "Error Assigning Entries:"
      when "take_entry"
        err_msg = "Error Taking Entries:"
      when "return_entry"
        err_msg = "Error Returning Entries:"
        succ_msg = "Entries successfully returned"
        assignee = 'vrtincom'
      when "unassign_all"
        err_msg = "Error Returning Entries:"
        succ_msg = "Entries successfully unassigned"
        assignee = 'vrtincom'

    std_msg_ajax(
      method: 'POST'
      url: url
      data: data
      success: (response) ->
        json = $.parseJSON(response)
        if json.error
          std_msg_error(err_msg, json.error)
        else
          std_msg_success(succ_msg, [])

          if json.cvs_username
            assignee = json.cvs_username

          if assignee
            $(selected_rows).each ->
              $(this).find('.entry-assignee').text(assignee)

      error: (response) ->
        std_api_error(response, 'Error assigning', reload: false)
    )
  else
    std_msg_error('Please select at least one ticket with an associated entry', [])

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

window.export_selected_jira_tasks = ()->
  form = $('#jira-tasks-disputes-export-form')
  selected_tasks = $('.imports_check_box:checked').map((i, el) => el.value).get()
  if !selected_tasks.length
    $('#jira-tasks-filter-input').val([])
  else
    $('#jira-tasks-filter-input').val(selected_tasks)
  form.submit()

