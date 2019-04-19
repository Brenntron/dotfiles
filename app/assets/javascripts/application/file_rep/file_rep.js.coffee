window.update_file_rep_status = () ->
  checked_disputes = []
  resolution = ""
  comment = ""

  checkboxes = $('#file-rep-datatable').find('.dispute_check_box')

  $(checkboxes).each ->
    if $(this).is(':checked')
      dispute_id = $(this).val()
      checked_disputes.push(dispute_id)

  status = $('#index-edit-ticket-status-dropdown').find('.ticket-status-radio:checked').val()
  comment = $('.ticket-status-comment').val()

  if status == "RESOLVED_CLOSED"
    if $('#index-edit-ticket-status-dropdown').find('#RESOLVED_CLOSED').is(':checked')
      resolution = $('input[name=ticket-resolution]:checked').val()
    else
      std_msg_error('No resolution selected', ['Please select a ticket resolution.'])
      return

  if resolution
    comment = $('.resolution-status-comment').val()

  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/file_rep/disputes/set_disputes_status"
    data:
      dispute_ids: checked_disputes
      status: status
      comment: comment
      resolution: resolution
    success_reload: false
    success: (response) ->
      std_msg_success('File Reputation Ticket statuses updated.', [], reload: true)
    error: (response) ->
      std_msg_error('Unable to update File Reputation Ticket status.')
  )

window.update_file_rep_status_on_show = () ->
  resolution = ""
  comment = ""

  dispute_id = $('#dispute_id').text().trim()
  status = $('#show-edit-ticket-status-dropdown').find('.fr-ticket-status-radio:checked').val()
  comment = $('.ticket-status-comment').val()

  if status == "RESOLVED_CLOSED"
    if $('#show-edit-ticket-status-dropdown').find('#file-status-closed').is(':checked')
      resolution = $('input[name=dispute-resolution]:checked').val()
    else
      std_msg_error('No resolution selected', ['Please select a ticket resolution.'])
      return

  if resolution
    comment = $('.resolution-status-comment').val()

  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/file_rep/disputes/set_disputes_status"
    data:
      dispute_ids: [dispute_id]
      status : status
      comment: comment
      resolution: resolution
    success_reload: false
    success: (response) ->
      std_msg_success('File Reputation Ticket statuses updated.', [], reload: true)
    error: (response) ->
      std_msg_error('Unable to update File Reputation Ticket status.', [])
  )
$ ->

  file_rep_url = $('#file-rep-datatable').data('source')
  current_url = window.location.href


  window.build_data = () ->

    if current_url.includes('/file_rep/disputes?f=')
#      if the current url includes the above, it is a standard search'
      status_param_regex = /f=(.*)/
      search_type = 'standard'
      search_name = status_param_regex.exec(current_url)[1]

      format_filerep_header(search_type, search_name)

      return {
        search_type: search_type
        search_name : search_name
      }
    else
      return

  window.format_filerep_header = (search_type, search_name) ->
    if search_type = 'standard'
      search_name = search_name.replace(/_/g, " ")
      new_header = '<span class="text-capitalize">' + search_name + ' tickets </span>'
    $('#filerep-index-title')[0].innerHTML = new_header

  $('#file-rep-datatable').dataTable
    processing: true
    serverSide: true
    ajax:
      url: file_rep_url
      data: build_data()
    order: [ [
      16
      'desc'
    ] ]
    pagingType: 'full_numbers'
    keys:
      columns: ':not(:first-child)'
    columnDefs: [
      {
        # Making checkbox row unorderable
        targets: [ 0 ]
        orderable: false
        searchable: false
      }
      {
        targets: [ 1 ]
        className: 'id-col'
      }
      {
        # Bolds the status
        targets: [ 2 ]
        className: 'font-weight-bold'
      }
    ]
    columns: [
      {
        data:'id'
        render: (data) ->
          return '<input type="checkbox" onclick="toggleRow(this)" name="cbox" class="dispute_check_box" id="cbox' + data + '" value="' + data + '" />'
      }
      {
#        need to zeropad this thing
        data: 'id'
        render: (data, type, full, meta) ->
          return '<a href="/escalations/file_rep/disputes/' + data + '">' + parseInt(data).pad(6) + '</a>'
      }
      { data: 'status' }
      { data: 'resolution' }
      {
        data: 'file_name'
        render: (data, type, full, meta) ->
          return '<a href="/escalations/file_rep/disputes/' + full['id'] + '">' + data + '</a>'
      }
      {
        data: 'sha256_hash'
        render: (data, type, full, meta) ->
          return '<a href="/escalations/file_rep/disputes/' + full['id'] + '"><span id="' + data + '_sha" title="' + data + '" class="esc-tooltipped file_rep_sha">' + data + '</span></a>'
      }
      {
        data: 'file_size'
        render: (data) ->
          return data + ' bytes'
      }
      { data: 'sample_type'}
      {
        data: 'disposition'
        render: (data) ->
          if data == 'Malicious'
            return '<span class="malicious text-capitalize">Malicious</span>'
          else
            return '<span class="text-capitalize">' + data + '</span>'

      }
      {
        data: 'detection_name'
        render: (data) ->
          if data == null || data == undefined
            return '<span class="missing-data">Detection not found</span>'
          else
            return data
      }
      {
        data: null
        render: () ->
          return '<span>Detection created</span>'
      }
      {
        data: 'in_zoo'
        className: "alt-col in_zoo"
        render: (data) ->
#          in_zoo is a boolean but something in the render function parses this to a string.
          if data == "true"
            return '<span class="glyphicon glyphicon-ok"></span>'
          else
            return ''

      }
      {
        data: 'sandbox_score'
        render: (data, type, full, meta) ->
          if full['sandbox_under'] == "true"
            return '<span class="score-col text-center">' + parseInt(data) + '</span>'
          else
            return '<span class="overdue score-col text-center">' + parseInt(data) + '</span>'
      }
      {
        data: 'threatgrid_score'
        render: (data, type, full, meta) ->
          if full['threatgrid_under'] == "true"
            return '<span class="score-col text-center">' + parseInt(data) + '</span>'
          else
            return '<span class="overdue score-col text-center">' + parseInt(data) + '</span>'
      }
      { data: 'reversing_labs_score'}
      {
        data: 'disposition_suggested'
        render: (data) ->
          if data == 'Malicious'
            return '<span class="malicious text-capitalize">Malicious</span>'
          else
            return  '<span class="text-capitalize">' + data + '</span>'
      }
      { data: 'created_at'}
      {
#        Submitter Type
        data: null
        render: () ->
          return "Submitter Type"
      }
      { data: 'customer_name' }
      { data: 'customer_company_name' }
      { data: 'customer_email' }
      {
        data: 'assignee'
        className: "alt-col"
        render: (data) ->
          if data == undefined
            return '<span class="missing-data">Unassigned</span> <span title="Assign to me" class="esc-tooltipped"><button id="index_ticket_assign" class="take-ticket-button" onClick="take_disputes()"/></span>'
          else
            return data + '<span title="Assign to me" class="esc-tooltipped"><button id="index_ticket_assign" class="take-ticket-button" onClick="take_disputes()"/></span>'
      }
    ]

  $('.toggle-vis-file-rep').each ->
#    toggle visible columns
      table = $('#file-rep-datatable').DataTable()
      column = table.column($(this).attr('data-column'))
      checkbox = $(this).find('input')
      if $(checkbox).prop('checked')
        column.visible true
      else
        column.visible false
      $(this).on 'click', ->
        $(checkbox).prop 'checked', !checkbox.prop('checked')
        column.visible !column.visible()
        return

      $(checkbox).on 'click', ->
        $(checkbox).prop 'checked', !checkbox.prop('checked')
        return
      return
      checkbox = $(this).find('input')

    $(document).on 'click ','.file_rep_sha', (e) ->
#      copy SHA on click
      copy_text_id = e.target.id
      copy_text = document.getElementById(copy_text_id);
      selection = window.getSelection();
      range = document.createRange();
      range.selectNodeContents(copy_text);
      selection.removeAllRanges();
      selection.addRange(range);
      document.execCommand("Copy");

    Number::pad = (size) ->
      s = String(this)
      while s.length < (size or 2)
        s = '0' + s
      s

    # dbinebri: adding in checkbox toggle column visible + widths on Show Page, Research tab
    $('#data-show-sandbox-cb').click -> $('#sandbox-report-wrapper').toggle()
    $('#data-show-tg-cb').click -> $('#threatgrid-report-wrapper').toggle()
    $('#data-show-reversing-cb').click -> $('#reversing-labs-report-wrapper').toggle()

    $('#data-show-sandbox-cb, #data-show-tg-cb, #data-show-reversing-cb').click ->
      if $('.dataset-cb:checked').length == 1
        $('#sandbox-report-wrapper, #threatgrid-report-wrapper, #reversing-labs-report-wrapper').removeClass('col-sm-4 col-sm-6').addClass('col-sm-12')
      else if $('.dataset-cb:checked').length == 2
        $('#sandbox-report-wrapper, #threatgrid-report-wrapper, #reversing-labs-report-wrapper').removeClass('col-sm-4 col-sm-12').addClass('col-sm-6')
      else if $('.dataset-cb:checked').length == 3
        $('#sandbox-report-wrapper, #threatgrid-report-wrapper, #reversing-labs-report-wrapper').removeClass('col-sm-6 col-sm-12').addClass('col-sm-4')
      return
