window.filerep_take_disputes = () ->
  dispute_ids = $('.dispute_check_box:checkbox:checked').map(() ->
    this.dataset['entryId']
    this.value
  ).toArray()

  if dispute_ids.length == 0
    std_msg_error('No Tickets Selected', ['Please select at least one ticket to assign.'])
    return

  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/file_rep/disputes/take_disputes"
    data: { dispute_ids: dispute_ids }
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      for dispute_id in response.dispute_ids
        $('#owner_' + dispute_id).text(response.username)
        $('#status_' + dispute_id).text("ASSIGNED")
      std_msg_success('Tickets successfully assigned', [response.dispute_ids.length + ' have been assigned to ' + response.username])
    error: (error) ->
      std_msg_error('Assign Issue(s) Error', [
        'Failed to assign ' + dispute_ids.length + ' issue(s).',
        'Due to: ' + error.responseJSON.message
      ])
  )

window.toolbar_file_rep_index_change_assignee = () ->

  entry_ids = $('.dispute_check_box:checkbox:checked').map(() ->
    Number(this.value)
  ).toArray()

  new_assignee = $('#index_target_assignee option:selected').val()

  data = {
    'dispute_ids': entry_ids,
    'new_assignee': new_assignee
  }

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/file_rep/disputes/change_assignee'
    method: 'POST'
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      std_msg_error('Unable to change assignee', [response.responseJSON.message])
  )

window.file_rep_take_dispute = (dispute_id) ->
  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/file_rep/disputes/take_dispute/" + dispute_id
    data: {}
    dispute_id: dispute_id
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      $('.inline-take-dispute-' + dispute_id).replaceWith("<button class='return-ticket-button inline-return-ticket-#{dispute_id}' title='Assign this ticket to me' onclick='file_rep_return_dispute(#{dispute_id});'></button>")
      $("#owner_#{dispute_id}").text(response.username)
      $('#status_' + dispute_id).text("ASSIGNED")
  )

window.file_rep_return_dispute = (dispute_id) ->
  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/file_rep/disputes/return_dispute/" + dispute_id
    data: {}
    dispute_id: dispute_id
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      $('.inline-return-ticket-' + dispute_id).replaceWith("<button class='take-ticket-button inline-take-dispute-#{dispute_id}' title='Assign this ticket to me' onclick='file_rep_take_dispute(#{dispute_id});'></button>")
      $("#owner_#{dispute_id}").text("Unassigned")
      $('#status_' + dispute_id).text("NEW")
  )

window.file_rep_show_take_dispute = (dispute_id) ->
  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/file_rep/disputes/take_dispute/" + dispute_id
    data: {}
    dispute_id: dispute_id
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      $("#dispute-assignee").text(response.username)
      $('#show-edit-ticket-status-button').text("ASSIGNED")
      $('.take-ticket-button').replaceWith("<button class='return-ticket-button' title='Return ticket to open queue' onclick='file_rep_show_return_dispute(#{dispute_id});'></button>")
  )

window.file_rep_show_return_dispute = (dispute_id) ->
  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/file_rep/disputes/return_dispute/" + dispute_id
    data: {}
    dispute_id: dispute_id
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      $("#dispute-assignee").text("Unassigned")
      $("#show-edit-ticket-status-button").text("NEW")
      $(".return-ticket-button").replaceWith("<button class='take-ticket-button' title='Assign this ticket to me' onclick='file_rep_show_take_dispute(#{dispute_id});'></button>")
  )

window.file_rep_show_change_assignee = (dispute_id) ->
  dispute_id = parseInt($('.case-id-tag')[0].innerHTML)
  new_assignee = $('#index_target_assignee option:selected').val()

  data = {
    'dispute_ids': [dispute_id],
    'new_assignee': new_assignee
  }
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/file_rep/disputes/change_assignee/"
    data: data
    dispute_id: dispute_id
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      window.location.reload()

  )

$ ->

  current_url = window.location.href
  time_submitted = ''
  last_updated = ''
  sandbox_score = ''
  threatgrid_score = ''

  window.triggerTooltips = (item) ->
    $('.tooltip_content').show()
    $('.nested-tooltipped').tooltipster
      theme: [
        'tooltipster-borderless'
        'tooltipster-borderless-customized'
      ]
      side: 'bottom'
    return

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
        window.location.reload()
      else if search_type == 'named'
        data = {
          search_type: search_type
          search_name: search_name
        }

    format_filerep_header(data)
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
        search_condition_tooltip = []
        search_conditions = JSON.parse(localStorage.search_conditions)
        new_header =
          '<div>Results for Advanced Search ' +
            reset_icon +
            '</div>'

        container = $('#filerep_searchref_container')
        for condition_name, condition of search_conditions
          if condition != ''
            condition_name = condition_name.replace(/_/g, " ").toUpperCase()
            condition_name_HTML = '<span class="search-condition-name text-uppercase">' + condition_name + ': </span>'

            if typeof condition == 'object'
              condition_HTML = '<span>' + condition.to + ' - ' + condition.from + '</span>'
            else
              condition_HTML = '<span>' + condition + '</span>'

            search_condition_tooltip.push(condition_name + ': ' + $(condition_HTML).text())

            container.append('<span class="search-condition">' + condition_name_HTML + condition_HTML + '</span>')


        if search_condition_tooltip.length > 0
          container.css('display', 'inline-block')
          container.addClass('esc-tooltipped')

          list = document.createElement('ul')
          $(list).addClass('tooltip_content')
          for  li in search_condition_tooltip
            item = document.createElement('li')
            item.appendChild(document.createTextNode(li))

            list.appendChild(item)

          container.prepend(list)
          $(list).hide()

          container.attr('data-tooltip-content', '.tooltip_content')


      else if search_type == 'named'
        new_header =
          '<div>Results for "' + search_name + '" Saved Search' +
          reset_icon +
          '</div>'

      else
        new_header = 'All File Reputation Tickets'

      $('#filerep-index-title')[0].innerHTML = new_header

  $('#file-rep-datatable').dataTable
    drawCallback: ( settings ) ->
      
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
      {
        data: 'status'
        render: (data, type, full, meta) ->
          return '<span id="status_'+ full['id']+'">' + data + '</span>'
      }
      { data: 'resolution' }
      {
        data: 'file_name'
        render: (data, type, full, meta) ->
          return '<a href="/escalations/file_rep/disputes/' + full['id'] + '">' + data + '</a>'
      }
      {
        data: 'sha256_hash'
        render: (data, type, full, meta) ->
          return '<span id="' + data + '_sha" title="' + data + '" class="esc-tooltipped file_rep_sha">' + data + '</span>'
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
          data = data.toLowerCase()
          if data == 'malicious'
            return '<span class="malicious text-capitalize"> malicious </span>'
          else
            return '<span class="text-capitalize"> clean </span>'
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
          data = data.toLowerCase()
          if data == 'malicious'
            return '<span class="malicious text-capitalize"> malicious</span>'
          else
            return  '<span class="text-capitalize"> clean </span>'
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
        data: 'assigned'
        className: "alt-col"
        render: (data, type, full, meta) ->
          if full.current_user == data
            return "<span id='owner_#{full.id}'> #{data} </span><button class='return-ticket-button inline-return-ticket-#{full.id}' title='Return ticket.' onclick='file_rep_return_dispute(#{full.id});'></button>"
          else if data == 'vrtincom' || data == ""
            return "<span id='owner_#{full.id}'>Unassigned</span> <span title='Assign to me' class='esc-tooltipped'><button class='take-ticket-button inline-take-dispute-#{full.id}' onClick='file_rep_take_dispute(#{full.id})'/></button></span>"
          else
            return data
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
\    # dbinebri: adding in checkbox toggle column visible + widths on Show Page, Research tab
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


$ ->
  ## Create detection form interaction
  $('#create-detection-dialog').dialog
    autoOpen: false,
    minWidth: 520,
    classes: {
      "ui-dialog": "form-dialog"
    },
    position: { my: "top center", at: "top center", of: window }


  # Trigger Create Detection dialog
  window.amp_detection_dialog = () ->
    $('#create-detection-dialog').dialog('open')
    window.amp_detection_naming()


  # Hide / Show of Detection Name inputs
  window.amp_detection_naming = () ->
    # Detection name can only be changed if user is setting a sample to malicious
    # or keeping it malicious. Hiding detection name part of form if not needed
    naming_section = $('#new-amp-detection-name-section')
    if $('#new-amp-detection-disp').val().toLowerCase() == 'malicious'
      $(naming_section).show()
    else
      $(naming_section).hide()

  # Class toggle for if user choses to not use category dropdown
  window.amp_category_naming = () =>
    # There is a category dropdown in the naming form to follow the conventions
    # of ClamAV. But a user can opt not to use this.
    # This makes it clearer that the dropdown will not add anything to this section of the name
    cat_selection = $('#new-amp-detection-name-cat')
    if $(cat_selection).val() == ''
      $(cat_selection).addClass('missing-data')
    else
      if $(cat_selection).hasClass('missing-data')
        $(cat_selection).removeClass('missing-data')



  # Prepare form info for sending to AMP
  window.amp_detection_submission = (e) ->
    e.preventDefault()
    # Get sha
    sha256_hash = $('#sha256_hash')[0].innerText
    # Get form info
    new_disp = $('#new-amp-detection-disp').val()
    new_detection_name = ''
    if new_disp.toLowerCase() == 'malicious'
      new_name_pre = $('#new-amp-detection-name-pre').val()
      new_name_cat = $('#new-amp-detection-name-cat').val()
      new_name_txt = $('#new-amp-detection-name-middle').val()
      # Don't add extra period unless they want to use an actual category
      if new_name_cat == ''
        new_detection_name = new_name_pre + '.' + new_name_txt + '.Talos'
      else
        new_detection_name = new_name_pre + '.' + new_name_cat + '.' + new_name_txt + '.Talos'
      detection_array = {name: new_detection_name, disposition: new_disp}
    else
      detection_array = {disposition: new_disp}

    comment = $('#new-amp-detection-comment').val()
    # temp just to keep page from refreshing on click of submit
    return false


