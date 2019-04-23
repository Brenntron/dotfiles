$ ->
  current_url = window.location.href;
  time_submitted = ''
  last_updated = ''
  sandbox_score = ''
  threatgrid_score = ''

  $(window).click (e) ->
    if !e.target.closest('.daterangepicker')
     $("#advanced-search-dropdown").hide()

  window.file_rep_reset_search = () ->
    inputs = document.getElementsByClassName('form-control')
    time_submitted = ''
    last_updated = ''
    sandbox_score = ''
    threatgrid_score = ''

    for i in inputs
      i.value = ""
      if $(i).hasClass('ui-slider')
        values = [ 25, 75 ]
        $(i).slider({
          values: values
        })

        slider_1 = $(i).find('.ui-slider-handle')[0]
        slider_2 = $(i).find('.ui-slider-handle')[1]
        $(slider_1).text(values[0])
        $(slider_2).text(values[1])

  file_rep_url = $('#file-rep-datatable').data('source')

  window.refresh_localStorage = () ->
    localStorage.removeItem('search_type')
    localStorage.removeItem('search_name')
    localStorage.removeItem('search_conditions')

  window.refresh_url = () ->
    if current_url.includes('/file_rep/disputes?f=')
      new_url = current_url.split('?f=')[0]
      window.location.replace(new_url)
    else
      location.reload()

  $(document).on 'click', '#refresh-filter-button', (e) ->
    refresh_localStorage()
    refresh_url()

  window.build_named_search = (search_name) ->
    localStorage.search_type = 'named'
    localStorage.search_name = search_name
    localStorage.removeItem('search_conditions')

    refresh_url()

  window.build_contains_search = (contains) ->
    refresh_localStorage()
    refresh_url()



  window.build_advanced_data = () ->
    form = $('#filerep_disputes-advanced-search-form')
    localStorage.search_type = 'advanced'
    localStorage.search_name = form.find('input[name="search_name"]').val()
    localStorage.search_conditions = JSON.stringify(
      id: form.find('input[id="caseid-input"]').val()
      created_at: time_submitted
      updated_at: last_updated
      status: form.find('input[id="status-input"]').val()
      resolution: form.find('input[id="resolution-input"]').val()
      assigned: form.find('input[id="assignee-input"]').val()
      file_name: form.find('input[id="file-name-input"]').val()
      file_size: form.find('input[id="file-size-input"]').val()
      sha256_hash: form.find('input[id="sha256-input"]').val()
      sample_type: form.find('input[id="sample-type-input"]').val()
      disposition: form.find('input[id="amp-disposition-input"]').val()
      disposition_suggested: form.find('input[id="suggested-disposition-input"]').val()
      sandbox_score: sandbox_score
      threatgrid_score: threatgrid_score
      detection_name: form.find('input[id="amp-detection-name-input"]').val()
      in_zoo: form.find('input[id="in-sample-zoo-input"]:checked').val()
      reversing_labs: form.find('input[id="reversing-labs-input"]').val()
      submitter_type: form.find('input[id="submitter-type-input"]').val()
      customer_type: form.find('input[id="customer-type-input"]').val()
      customer_name: form.find('input[id="customer-name-input"]').val()
      customer_email: form.find('input[id="customer-email-input"]').val()
      customer_company_name: form.find('input[id="customer-company-input"]').val()
    )
    refresh_url()

  window.build_data = () ->
    data = {
      search_type: ''
      search_name: ''
    }

    if location.search != ''
#      if the location.search has value, it is a standard search

      data ={
        search_type : 'standard'
        search_name : location.search.replace('?f=', '')
      }
      refresh_localStorage()

    else if localStorage.search_type

      {search_type, search_name, search_conditions} = localStorage

      if search_type == 'advanced'
        search_conditions = JSON.parse(search_conditions)

        if search_conditions.in_zoo
          {in_zoo} = search_conditions.in_zoo
          search_conditions.in_zoo = in_zoo == 'checked' ? true : false

        data ={
            search_type: search_type
            search_name: search_name
            search_conditions: search_conditions
          }
      else if search_type == 'named'
        data = {
          search_type: search_type
          search_name: search_name
        }

    format_filerep_header(data)
    console.log(data)
    return data

  window.format_filerep_header = (data) ->

    if data != undefined
      reset_icon = '<span id="refresh-filter-button" class="reset-filter esc-tooltipped" title="Clear Search Results"></span>'
      {search_type, search_name} = data

      if search_type == 'standard'
        new_header =
          '<div>' +
          '<span class="text-capitalize">' + search_name.replace(/_/g, " ") + ' tickets </span>' +
          reset_icon +
          '</div>'

      else if search_type == 'advanced'
        new_header =
          '<div>Results for Advanced Search ' +
          reset_icon +
          '</div>'

      else if search_type == 'named'
        new_header =
          '<div>Results for "' + search_name + '" Saved Search' +
          reset_icon +
          '</div>'

      else
        new_header = 'All File Reputation Tickets'

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

  $(document).on 'focus', '#time-submitted-input', (e) ->
    if time_submitted != ''
      placeholder = time_submitted.to + ' - ' + time_submitted.from
    else
      placeholder = 'MM-DD-YYYY'
    $('#time-submitted-input').attr('placeholder', placeholder)

    $('#time-submitted-input').daterangepicker( {},
      (start, end) ->
        time_submitted = {
          from : start.format('YYYY-MM-DD')
          to : end.format('YYYY-MM-DD')
        }
        $('#advanced-search-dropdown').show()
        $('#advanced-search-dropdown').css('display', 'block')
    )

  $(document).on 'focus', '#last-updated-input', () ->
    if last_updated != ''
      placeholder = last_updated.to + ' - ' + last_updated.from
    else
      placeholder = 'MM-DD-YYYY'
    $('#last-updated-input').attr('placeholder', placeholder)

    $('#last-updated-input').daterangepicker( {},
      (start, end) ->
        last_updated = {
          from : start.format('YYYY-MM-DD')
          to : end.format('YYYY-MM-DD')
        }
    )
  $('#sandbox-score-input').slider(
    {
      range: true,
      min: 0,
      max: 100,
      values: [ 25, 75 ]
      create: (ui) ->
        values = $(this).slider("values")

        slider_1 = $('#sandbox-score-input .ui-slider-handle')[0]
        slider_2 = $('#sandbox-score-input .ui-slider-handle')[1]
        $(slider_1).text(values[0])
        $(slider_2).text(values[1])

      slide: ( event, ui ) ->
        {values} = ui

        slider_1 = $('#sandbox-score-input .ui-slider-handle')[0]
        slider_2 = $('#sandbox-score-input .ui-slider-handle')[1]
        $(slider_1).text(values[0])
        $(slider_2).text(values[1])

        sandbox_score = {
          from: values[0]
          to : values[1]
        }
    })

  $('#tg-score-input').slider(
    {
      range: true,
      min: 0,
      max: 100,
      values: [ 25, 75 ]
      create: (ui) ->
        values = $(this).slider("values")

        slider_1 = $('#tg-score-input .ui-slider-handle')[0]
        slider_2 = $('#tg-score-input .ui-slider-handle')[1]
        $(slider_1).text(values[0])
        $(slider_2).text(values[1])

      slide: ( event, ui ) ->
        {values} = ui

        slider_1 = $('#tg-score-input .ui-slider-handle')[0]
        slider_2 = $('#tg-score-input .ui-slider-handle')[1]
        $(slider_1).text(values[0])
        $(slider_2).text(values[1])

        threatgrid_score = {
          from: values[0]
          to : values[1]
        }
    })

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
