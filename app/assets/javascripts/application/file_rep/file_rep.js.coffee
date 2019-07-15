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
    success: (response) ->
      if checked_disputes.length == 1
        std_msg_success('File Reputation Ticket status updated', [])
      else if checked_disputes.length > 1
        std_msg_success('File Reputation Ticket statuses updated', [])
      window.location.reload()
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
      std_msg_success('File Reputation Ticket status updated', [])
      window.location.reload()
    error: (response) ->
      std_msg_error('Unable to update File Reputation Ticket status.', [])
  )


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
    error_prefix: 'Error updating ticket'
    success: (response) ->
      for dispute_id in response.dispute_ids
        # dbinebri: adding the take/return button swap logic here
        $('.take-ticket-button').replaceWith("<button class='return-ticket-button' title='Return ticket to open queue' onclick='file_rep_return_dispute(#{dispute_id});'></button>")
        $('#owner_' + dispute_id).text(response.username).removeClass('missing-data')
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
    error_prefix: 'Error updating ticket'
    success: (response) ->
      $('.inline-take-dispute-' + dispute_id).replaceWith("<button class='return-ticket-button inline-return-ticket-#{dispute_id}' title='Assign this ticket to me' onclick='file_rep_return_dispute(#{dispute_id});'></button>")
      $("#owner_#{dispute_id}").text(response.username).removeClass('missing-data')
      $('#status_' + dispute_id).text("ASSIGNED")
  )

window.file_rep_return_dispute = (dispute_id) ->
  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/file_rep/disputes/return_dispute/" + dispute_id
    data: {}
    dispute_id: dispute_id
    error_prefix: 'Error updating ticket'
    success: (response) ->
      $('.inline-return-ticket-' + dispute_id).replaceWith("<button class='take-ticket-button inline-take-dispute-#{dispute_id}' title='Assign this ticket to me' onclick='file_rep_take_dispute(#{dispute_id});'></button>")
      $("#owner_#{dispute_id}").text("Unassigned").addClass('missing-data')
      $('#status_' + dispute_id).text("NEW")
  )

window.file_rep_show_take_dispute = (dispute_id) ->
  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/file_rep/disputes/take_dispute/" + dispute_id
    data: {}
    dispute_id: dispute_id
    error_prefix: 'Error updating ticket'
    success: (response) ->
      $("#dispute-assignee").text(response.username).removeClass('missing-data')
      $('#show-edit-ticket-status-button').text("ASSIGNED")
      $('.take-ticket-button').replaceWith("<button class='return-ticket-button esc-tooltipped' title='Return ticket to open queue' onclick='file_rep_show_return_dispute(#{dispute_id});'></button>")
  )

window.file_rep_show_return_dispute = (dispute_id) ->
  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/file_rep/disputes/return_dispute/" + dispute_id
    data: {}
    dispute_id: dispute_id
    error_prefix: 'Error updating ticket'
    success: (response) ->
      $("#dispute-assignee").text("Unassigned").addClass('missing-data')
      $("#show-edit-ticket-status-button").text("NEW")
      $(".return-ticket-button").replaceWith("<button class='take-ticket-button esc-tooltipped' title='Assign this ticket to me' onclick='file_rep_show_take_dispute(#{dispute_id});'></button>")
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
    error_prefix: 'Error updating ticket'
    success: (response) ->
      window.location.reload()
  )

$ ->
  file_rep_url = $('#file-rep-datatable').data('source')
  current_url = window.location.href
  sorting_request = false
  time_submitted = ''
  last_updated = ''
  sandbox_score = ''
  threatgrid_score = ''

  $(document).on 'click', '.sorting[aria-controls="file-rep-datatable"]', () ->
    sorting_request = true

  window.triggerTooltips = (item) ->
    $('.tooltip_content').show()
    $('.nested-tooltipped').tooltipster
      theme: [
        'tooltipster-borderless'
        'tooltipster-borderless-customized'
      ]
      side: 'bottom'
    return

  window.reset_slider = (slider) ->
    if slider == "sandbox"
      sandbox_score = ''
    else
      threatgrid_score = ''

  window.file_rep_reset_search = () ->
    inputs = document.getElementsByClassName('form-control')
    time_submitted = ''
    last_updated = ''
    sandbox_score = ''
    threatgrid_score = ''

    for i in inputs
      i.value = ""

      if $(i).is('#status-input, #sha256-input, #amp-disposition-input, #sandbox-score-input, #tg-score-input, #suggested-disposition-input')
        $(i).closest('.form-group').removeClass('hidden')
      else
        $(i).closest('.form-group').addClass('hidden')

      if $(i).hasClass('ui-slider')
        values = [ 0, 100 ]
        $(i).slider({
          values: values
        })

        slider_1 = $(i).find('.ui-slider-handle')[0]
        slider_2 = $(i).find('.ui-slider-handle')[1]
        $(slider_1).text(values[0])
        $(slider_2).text(values[1])


  window.refresh_localStorage = () ->
    localStorage.removeItem('search_type')
    localStorage.removeItem('search_name')
    localStorage.removeItem('search_conditions')

  window.refresh_url = (href) ->
    {search_type, search_name} = localStorage
    url_check = current_url.split('/escalations/file_rep/disputes/')[0]
    new_url = '/escalations/file_rep/disputes'

    if href != undefined
      window.location.replace(new_url + href)

    if !href && typeof parseInt(url_check) == 'number'
      window.location.replace('/escalations/file_rep/disputes')

  $(document).on 'click', '#refresh-filter-button', (e) ->
    refresh_localStorage()
    refresh_url()

  window.build_named_search = (search_name) ->
    localStorage.search_type = 'named'
    localStorage.search_name = search_name
    localStorage.removeItem('search_conditions')

    refresh_url()

  window.build_contains_search = () ->
    search_string = $('#file-rep-search .search-box').val()
    if search_string == ''
      refresh_localStorage()
      refresh_url()
    else
      localStorage.search_type = 'contains'
      localStorage.search_name = ''
      localStorage.search_conditions = JSON.stringify({value:search_string})
    refresh_url()



  window.build_advanced_data = () ->
    form = $('#filerep_disputes-advanced-search-form .form-group')

    #  if form groups are hidden, wipe their values
    $('#filerep_disputes-advanced-search-form .form-group.hidden').find('input').val('')

    if $('#tg-score-input').closest('.form-group').hasClass('.hidden')
      threatgrid_score = {}
    if $('#sandbox_score-input').closest('.form-group').hasClass('.hidden')
      sandbox_score = {}
    if $('time_submitted-input').closest('.form-group').hasClass('.hidden')
      last_updated = {}
    if $('last-updated-input').closest('.form-group').hasClass('.hidden')
      time_submitted = {}

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
    file_rep_reset_search()


  window.build_data = () ->
    data = {
      search_type: ''
      search_name: ''
      selected_cases: []
    }

    $('.dispute_check_box:checked').each ->
      case_id =  $(this).attr('value')
      data.selected_cases.push(case_id)

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
      else if search_type == 'contains'
        search_conditions = JSON.parse(search_conditions)
        data = {
          search_type: search_type
          search_conditions: search_conditions
        }

    format_filerep_header(data)
    return data

  window.format_filerep_header = (data) ->
    container = $('#filerep_searchref_container')
    if data != undefined && container.length > 0
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

        for condition_name, condition of search_conditions
          if condition != ''
            condition_name = condition_name.replace(/_/g, " ").toUpperCase()
            condition_name_HTML = '<span class="search-condition-name text-uppercase">' + condition_name + ': </span>'

            if typeof condition == 'object'
              condition_HTML = '<span>' + condition.from  + ' - ' + condition.to+ '</span>'
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

      else if search_type == 'contains'
        search_conditions = JSON.parse(localStorage.search_conditions)
        new_header =
          '<div>Results for "' + search_conditions.value + '" '+
            reset_icon +
            '</div>'

      else
        new_header = 'All File Reputation Tickets'
      $('#filerep-index-title')[0].innerHTML = new_header

  window.export_file_rep = () ->
    data = build_data()
    if 'advanced' == data.search_type
      data.search_name = null
    data_json = JSON.stringify(data)
    $('#index-export-data-input').val(data_json)
    return true

  $('#file-rep-datatable').dataTable
    drawCallback: ( settings ) ->
      if localStorage.search_name

        {search_type, search_name, search_conditions } = localStorage
        last_tr = $('.filerep-named-search-list .saved-search').last().text()

        ### check variables below
            text_check makes sure that the last table row doesn't match the named search being saved now
            search_name_check makes sure that the search is being saved as a named search
            Not super complicated, but that if statement was looking gross and confusing
        ###

        text_check = last_tr.trim() != search_name.trim()
        search_name_check = search_name != ''

        if search_type == 'advanced' && search_name_check && text_check
          ###
            creating temporary tr for the filter dropdown
            attributes added then onclick events 
          ###
          new_tr = document.createElement('tr')
          new_td = document.createElement('td')
          new_link =  document.createElement('a')
          new_delete_image = document.createElement('img')
          new_delete = document.createElement('a')

          $(new_tr).attr('id','temp_row')
          $(new_link).addClass('input-truncate saved-search esc-tooltipped')
            .attr('title', search_name)
            .text(search_name)
          $(new_delete).addClass("delete-search")
          $(new_delete_image).addClass('delete-search-image')


          $(new_link).on 'click', () ->
            window.build_named_search(search_name)
          $(new_delete).on 'click', () ->
            window.delete_disputes_named_search(this,  search_name)
            refresh_localStorage()

          $(new_tr).append(new_td)
          $(new_td).append(new_link)
          $(new_td).append(new_delete)
          $(new_delete).append(new_delete_image)
          $('.filerep-named-search-list').append(new_tr)



    processing: true
    serverSide: true
    ajax:
      url: file_rep_url
      data: build_data()
      error: (error) ->

        if sorting_request
          error_msg = 'Unable to process sorting request.'
        else
          if localStorage.search_type || location.search != ''
            error_msg = 'Unable to process search request.'
          else
            error_msg = 'Unable to process request.'

        error_msg = error.statusText + ': ' + error_msg

        std_msg_error('Error Occurred', [error_msg])

        sorting_request = false

    order: [ [
      16
      'desc'
    ] ]
    pagingType: 'full_numbers'
    keys:
      columns: ':not(:first-child)'
    columnDefs: [
      {
        # Making checkbox and RL score rows unorderable
        targets: [ 0, 14 ]
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
        render: (data, type, full, meta) ->
          return '<input type="checkbox" onclick="toggleRow(this)" name="cbox" class="dispute_check_box" id="cbox' + data + '" value="' + data + '" data-sha="' + full['sha256_hash'] + '"/>'
      }
      {
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
          if data == "N/A" || data == "Unknown" || data == "Missing" || data == ""
            data = '<span class="missing-data unknown-file"></span>'
          return data
      }
      {
        data: 'sha256_hash'
        render: (data) ->
          return '<span id="' + data + '_sha" title="' + data + '" class="esc-tooltipped file_rep_sha">' + data + '</span>'
      }
      {
        data: 'file_size'
        render: (data) ->
          return data + ' KB'
      }
      {
        data: 'sample_type'
        render: (data) ->
          return '<span title="' + data + '" class="esc-tooltipped">' + data + '</span>'
      }
      {
        data: 'disposition'
        render: (data) ->
          if data == null
            return
          if data == 'malicious'
            return '<span class="malicious text-capitalize">' + data + '</span>'
          else
            return  '<span class="text-capitalize">' + data + '</span>'
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
        data: 'detection_last_set'
        render: (data) ->
          if data
            return moment(new Date(data)).utc().format('MMM D, YYYY h:mm A z')
          else
            return ''
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
          data = parseInt(data)
          if isNaN(data)
            return '<span class="score-col missing-data text-center no-score"></span>'
          else
            if full['sandbox_under'] == "true"
              return '<span class="score-col text-center">' + parseInt(data) + '</span>'
            else
              return '<span class="overdue score-col text-center">' + parseInt(data) + '</span>'
      }
      {
        data: 'threatgrid_score'
        render: (data, type, full, meta) ->
          data = parseInt(data)
          if isNaN(data)
            return '<span class="score-col missing-data text-center no-score"></span>'
          else
            if full['threatgrid_under'] == "true"
              return '<span class="score-col text-center">' + data + '</span>'
            else
              return '<span class="overdue score-col text-center">' + data + '</span>'
      }
      {
        data: 'reversing_labs_score'
        className: 'rl-col'
        render: (data, type, full, meta) ->
          if full['reversing_labs_count'] == '0'
            return '<span class="missing-data">Not in RL</span>'
          else if data
            score_id_selector = full['id']
            scanner_list = full['reversing_labs_scanners']
            rl_score = data
            rl_count = full['reversing_labs_count']
            score_id_selector = '#rl-score-id-' + score_id_selector
            rl_hover_table = ''

            if rl_count == "0"
              $(score_id_selector).tooltipster
                theme: [
                  'tooltipster-borderless'
                  'tooltipster-borderless-customized'
                ]
                side: 'bottom'
                content: 'Not in Reversing Labs.'
                trigger: 'hover'

            else
              scanners_list = scanner_list
              # file_rep_datatable.rb is doing a .to_json but it needs a fix
              scanners_list = scanners_list.replace(/&quot;/g,'"')

              obj_scanners = JSON.parse(scanners_list)

              mal_results = []
              unk_results = []

              # each scanner entry, this is where to handle the logic for each scanner
              $(obj_scanners).each ->
                if this.result == ""
                  unk_results.push(this)
                else
                  mal_results.push(this)

              rl_hover_table +=
                '<table class=\'rl-header\'><tr class=\'top\'><td colspan=\'2\'>Reversing Labs Details ' +
                  '<span id=\'rl-score-hover\'>' + rl_score + '/' + rl_count + '</span></td></tr>' +
                  '<tr class=\'second\'><td class=\'left\'>AV Vendor</td><td class=\'right\'>Results</td></tr></table>' +
                  '<table class=\'rl-content\'>'

              $(mal_results).each ->
                rl_hover_table += '<tr><td class=\'left\'>' + this.name + '</td><td class=\'right rl-scanner-mal\'>' + this.result + '</td></tr>'
              $(unk_results).each ->
                rl_hover_table += '<tr><td class=\'left\'>' + this.name + '</td><td class=\'right rl-scanner-unk\'>Not Detected</td></tr>'

            return '<span title="' + rl_hover_table + '" class="score-col text-center rl-hover" ' + 'id="rl-score-id-' + full['id'] + '" ><a>' + data + ' / ' + full['reversing_labs_count'] + '</a></span>'
          else
            return ''
      }
      {
        data: 'disposition_suggested'
        render: (data) ->
          if data == null
            return
          if data.toLowerCase() == 'malicious'
            return '<span class="malicious text-capitalize">' + data + '</span>'
          else
            return  '<span class="text-capitalize">' + data + '</span>'

      }
      {
        data: 'description'
        render: (data) ->
          return '<span title="' + data + '" class="esc-tooltipped dispute-description">' + data + '</span>'
      }
      {
        data: 'created_at'
        render: (data) ->
          if data
            return moment(data, "YYYY-MM-DD HH:mm").format("YYYY-MM-DD HH:mm")
          else
            return ''
      }
      {
        data: 'submitter_type'

      }
      { data: 'customer_name' }
      { data: 'customer_company_name' }
      { data: 'customer_email' }
      {
        data: 'assigned'
        className: "alt-col assignee-col"
        render: (data, type, full, meta) ->
          if full.current_user == data
            return "<span id='owner_#{full.id}'> #{data} </span><button class='return-ticket-button inline-return-ticket-#{full.id}' title='Return ticket.' onclick='file_rep_return_dispute(#{full.id});'></button>"
          else if data == 'vrtincom' || data == ""
            return "<span class='missing-data missing-data-index' id='owner_#{full.id}'>Unassigned</span> <span title='Assign to me' class='esc-tooltipped'><button class='take-ticket-button inline-take-dispute-#{full.id}' onClick='file_rep_take_dispute(#{full.id})'/></button></span>"
          else
            return data
      }
    ]

#
  $('#file-rep-datatable').on 'draw.dt', ->
    $('.rl-hover').tooltipster
      theme: [
        'tooltipster-borderless'
        'tooltipster-borderless-customized'
        'tooltipster-rl-hover'
      ]
      side: 'bottom'
      contentAsHTML: true
      autoClose: false
      trigger: 'custom'
      triggerOpen:
        mouseenter: true
        click: true
      triggerClose:
        mouseleave: true
        click: true
        scroll: true
      interactive: true
      updateAnimation: false

    return



  $('.toggle-vis-file-rep').each ->
#       toggle visible columns
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

      # dbinebri: add a click tooltip that co-exists with the hover tooltip
      $(this).after('<div class="copied-sha-tooltip">Copied!</div>')
      $('.copied-sha-tooltip').animate({opacity: '1'}, 200).delay(500).fadeOut()


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
      values: [ 0, 100 ]
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
      values: [ 0, 100 ]
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


$ ->
  # AMP history dialog init here
  $('#amp-history-dialog').dialog
    autoOpen: false
    width: 900
    height: 400
    minWidth: 900
    minHeight: 400
    resizable: true
    position: { at: "right top" }


  ## Create detection form dialog
  $('#create-detection-dialog').dialog
    autoOpen: false,
    minWidth: 520,
    minHeight: 560,
    resizable: false,

    classes: {
      "ui-dialog": "form-dialog"
    },
    position: { my: "top center", at: "top center", of: window }


  # Trigger Create Detection dialog
  window.amp_detection_dialog = () ->
    $('#create-detection-dialog').dialog('open')
    window.amp_detection_naming()


  ## Create detection form interaction

  # Hide / Show of Detection Name inputs
  window.amp_detection_naming = (page) ->
    # Detection name can only be changed if user is setting a sample to malicious
    # or keeping it malicious. Hiding detection name part of form if not needed
    naming_section = ''
    if page == 'show'
      naming_section = $('#new-amp-detection-name-section')
    else if page == 'index'
      naming_section = $('#new-amp-detection-name-dd-section')

    if $('#new-amp-detection-disp').val() == 'malicious'
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
  window.amp_detection_submission = (e, page) ->
    e.preventDefault()

    # Get form info
    new_disp = $('#new-amp-detection-disp').val()
    new_detection_name = ''
    if new_disp == 'malicious'
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

    dispute_id = parseInt($('#dispute_id').text())
    old_disposition = $('.disposition').text()
    comment = $('#new-amp-detection-comment').val()

    # Grab sha data
    # From show page only one sha can be submitted
    sha256_hashes = []
    if page == 'show'
      # Get sha
      sha = $('#sha256_hash')[0].innerText
      sha256_hashes = [sha]

    # From index several shas could be submitted (from the users perspective)
    else if page == 'index'
      if $('.dispute_check_box:checked').length < 1
        std_msg_error('No Tickets Selected', ['Please select at least one ticket to submit detection for.'])
      else

      # Get all checked checkboxes
      $('.dispute_check_box:checked').each ->
        sha_val =  $(this).attr('data-sha')
        sha256_hashes.push(sha_val)

      console.log sha256_hashes
      console.log detection_array
    else
      alert('Where are you? How did you trigger this? Stahp it.')
      return false

    # Small format prep for success message:
    detection_name_msg = ''
    unless new_detection_name == ''
      detection_name_msg = ': ' + new_detection_name

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/file_rep/detections'
      method: 'POST'
      data: {
        'sha256_hashes': sha256_hashes
        'old_disposition': old_disposition
        'disposition': new_disp
        'detection_name': new_detection_name
        'comment': comment
        'dispute_id': dispute_id

      }
      success: (response) ->
        $('#create-detection-dialog').dialog('close')
        std_msg_success("Detection successfully created", ['<span class="code-snippet">' + sha256_hashes + '</span>', 'set to <span class="text-capitalize">' + new_disp + '</span> ' + detection_name_msg ], reload: true)
      error: (response) ->
        $('#create-detection-dialog').dialog('close')
        std_api_error(response, "Detection not created", reload: false)
    )

    return false


  # AMP detection data for File Rep > Show page, top right area
  window.detection_now = (sha256_hash) ->
    std_msg_ajax(
      method: 'GET'
      url: '/escalations/api/v1/escalations/file_rep/detections/' + sha256_hash + '/now'
      success_reload: false

      success: (response) ->
        # Object destructuring below for the response, enables cleaner code
        { disposition, detection_name, detection_last_set, last_fetched } = response
        unless disposition == '' || disposition == 'unseen'
          $('.amp-area .disposition').text(disposition)
          $('.amp-area .detection-name').text(detection_name)
          $('.amp-area .detection-last-updated').text(detection_last_set)
          $('.amp-area .detection-last-pulled').text(last_fetched)

          if disposition == 'malicious'
            $('.amp-area .disposition').addClass('disp-negative')

          history_icon = '<span class="amp-history-icon esc-tooltipped tooltipstered" title="View full available AMP history"></span>'
          $('.amp-area .detection-last-updated').append(history_icon)

          # Retain this event listener below, need to ensure all previous succeeds first
          $('.amp-history-icon').click ->
            $('#amp-history-dialog').dialog('open')

      error: (response) ->
        std_msg_error('Error with an API', ['There was an error retrieving data. Error - '+ response.responseJSON.message])
      complete: () ->
        $('.amp-area .inline-loader-wrapper').hide()
    )


  window.get_amp_history = (sha256_hash) ->
    # Fetch the AMP history, build the table and load into #amp-history-dialog
    std_msg_ajax(
      method: 'GET'
      url: '/escalations/api/v1/escalations/file_rep/detections/' + sha256_hash + '/history'
      success_reload: false
      success: (response) ->
        # Response.json is an array of objects with AMP poke data
        amp_hist_array = response.json
        amp_html = ''
        curr_row = ''

        if amp_hist_array.length == 0 || amp_hist_array == undefined
          $('#amp-history-icon').hide()
        else if amp_hist_array.length > 0
          # Each entry, build a new html row with that source data using object destructuring
          for entry in amp_hist_array
            {time, disposition, name, user, _poke_server, mode} = entry._source
            datetime = moment.utc(moment.unix(time)).format("MMMM DD, YYYY h:mm A z")
            if disposition == 'malicious'
              disposition = '<span class="disp-negative">' + disposition + '</span>'

            curr_row = '<tr><td>' + datetime + '</td><td class="capitalize">' + disposition + '</td><td>' + name + '</td><td>' + user + '</td><td>' + _poke_server + '</td><td>' + mode.toUpperCase() + '</td></tr>'

            amp_html += curr_row
        else
          amp_html = '<br><p>There was an error retrieving the AMP history.</p>'

        $('#amp-history-dialog table tbody').append(amp_html)

      error: (response) ->
       std_msg_error('Error with AMP', ['There was an error retrieving the AMP history.'])
    )



# TODO: This stuff maybe should be moved into its own file later, but dropping here because convenient
# (it's all for the comms tab of the show page)

# New Note

  $('#new-filerep-case-note-button').on "click", ->
    $('.new-case-note-row').show()
    $(this).hide()

  $('.new-filerep-case-note-cancel-button').on "click", ->
    $('.new-case-note-row').hide()
    $('#new-case-note-button').show()
    $('.new-case-note-textarea').empty()

  $('.new-filerep-case-note-save-button').on "click", ->
    comment = $('.new-case-note-textarea')[0].innerText
    dispute_id = $('input[name="dispute_id"]').val()
    user_id = $('input[name="current_user_id"]').val()

    if comment.trim().length > 0
      std_msg_ajax(
        method: 'POST'
        url: "/escalations/api/v1/escalations/file_rep/dispute_comments"
        data: {user_id: user_id, comment: comment, file_reputation_dispute_id: dispute_id}
        success_reload: true
        error_prefix: 'Note could not created.'
        failure_reload: false
      )
    else
      std_msg_error("Note is blank. Delete note?",'')


  $('.filerep-note-delete-button').on "click", ->
    $('.confirm').show()

    comment_id = $(this).attr('comment_id')
    current_user_id = $('input[name="current_user_id"]').val()

    std_msg_confirm('Are you sure you want to delete this note?', [])

    $('.confirm').on 'click', ->
      std_msg_ajax(
        method: 'DELETE'
        url: "/escalations/api/v1/escalations/file_rep/dispute_comments/#{comment_id}"
        data: {current_user_id: current_user_id}
        success_reload: true
        error: (response) ->
          std_msg_error("Note could not be deleted", [response.responseJSON.message], reload: false)
          $('.confirm').hide()
      )

  # Editing a Note

  $('.filerep-update-note').on "click", ->
    comment_id = $(this).attr('comment_id')
    current_user_id = $('input[name="current_user_id"]').val()
    editable_note_block = $(".note-block" + comment_id)
    updated_comment = editable_note_block[0].innerText

    std_msg_ajax(
      method: 'PUT'
      url: "/escalations/api/v1/escalations/file_rep/dispute_comments/#{comment_id}"
      data: {current_user_id: current_user_id, comment: updated_comment}
      success_reload: true
      error: (response) ->
        std_api_error(response, "Note could not be updated.", reload: false)
    )


  $(document).ready ->
    # Make sure you're on show page to fetch the AMP data
    if $('body.escalations--file_rep--disputes-controller').hasClass('show-action')
      curr_sha256_hash = $('#sha256_hash').text()

      # Retrieve current AMP info and history
      detection_now(curr_sha256_hash)
      get_amp_history(curr_sha256_hash)

    $('select[name="file-rep-datatable_length"]').on "change", ->
      data = {}
      data['entriesperpage'] = $('select[name="file-rep-datatable_length"]').val()
      std_msg_ajax(
        url: "/escalations/api/v1/escalations/user_preferences/update"
        method: 'POST'
        data: {data, name: 'FileRepEntriesPerPage'}
        dataType: 'json'
        success: (response) ->
      )

    $('#file-rep-datatable_paginate').on "click", ->
      data = {}
      data['currentpage'] = $('#file-rep-datatable').DataTable().page()
      std_msg_ajax(
        url: "/escalations/api/v1/escalations/user_preferences/update"
        method: 'POST'
        data: {data, name: 'FileRepCurrentPage'}
        dataType: 'json'
        success: (response) ->
      )

    $('#file-rep-datatable th').on "click", ->
      setTimeout (-> # Wait until after the sorting event is finished before saving the result
        data = {}
        data['sortorder'] = $('#file-rep-datatable').DataTable().order()
        std_msg_ajax(
          url: "/escalations/api/v1/escalations/user_preferences/update"
          method: 'POST'
          data: {data, name: 'FileRepSortOrder'}
          dataType: 'json'
          success: (response) ->
        )
      ), 100


    $('.toggle-vis-file-rep').on "click", ->
      data = {}
      data['status'] = $("#status-checkbox").is(':checked')
      data['resolution'] = $("#resolution-checkbox").is(':checked')
      data['file-name'] = $("#file-name-checkbox").is(':checked')
#      data['sha256'] = $("#sha256-checkbox").is(':checked')
      data['file-size'] = $("#file-size-checkbox").is(':checked')
      data['sample-type'] = $("#sample-type-checkbox").is(':checked')
      data['amp-disp'] = $("#amp-disp-checkbox").is(':checked')
      data['amp-name'] = $("#amp-name-checkbox").is(':checked')
      data['amp-last-set'] = $("#amp-last-set-checkbox").is(':checked')
      data['in-zoo'] = $("#in-zoo-checkbox").is(':checked')
      data['sandbox-score'] = $("#sandbox-score-checkbox").is(':checked')
      data['threatgrid-score'] = $("#threatgrid-score-checkbox").is(':checked')
      data['reversing-labs'] = $("#reversing-labs-checkbox").is(':checked')
      data['suggested-disp'] = $("#suggested-disp-checkbox").is(':checked')
      data['dispute-details'] = $("#dispute-details-checkbox").is(':checked')
      data['time-submitted'] = $("#time-submitted-checkbox").is(':checked')
      data['submitter-type'] = $("#submitter-type-checkbox").is(':checked')
      data['customer-name'] = $("#customer-name-checkbox").is(':checked')
      data['customer-org'] = $("#customer-org-checkbox").is(':checked')
      data['customer-email'] = $("#customer-email-checkbox").is(':checked')
      data['assignee'] = $("#assignee-checkbox").is(':checked')


      std_msg_ajax(
        url: "/escalations/api/v1/escalations/user_preferences/update"
        method: 'POST'
        data: {data, name: 'FileRepColumns'}
        dataType: 'json'
        success: (response) ->
        error: () ->
      )

    if window.location.pathname == '/escalations/file_rep/disputes'
      std_msg_ajax(
        method: 'POST'
        url: "/escalations/api/v1/escalations/user_preferences/"
        data: {name: 'FileRepColumns'}
        success: (response) ->
          response = JSON.parse(response)

          $.each response, (column, state) ->
            if state == true
              $("##{column}-checkbox").prop('checked', true)
              $('#file-rep-datatable').DataTable().column("##{column}").visible true
            else
              $("##{column}-checkbox").prop('checked', false)
              $('#file-rep-datatable').DataTable().column("##{column}").visible false

      )



      std_msg_ajax(
        method: 'POST'
        url: "/escalations/api/v1/escalations/user_preferences/"
        data: {name: 'FileRepSortOrder'}
        success: (response) ->
          response = JSON.parse(response)
          $('#file-rep-datatable').DataTable().order(response.sortorder).draw()
        error: () ->
      )

      std_msg_ajax(
        method: 'POST'
        url: "/escalations/api/v1/escalations/user_preferences/"
        data: {name: 'FileRepCurrentPage'}
        success: (response) ->
          response = JSON.parse(response)
          $('#file-rep-datatable').DataTable().page(response.currentpage).draw('page')
        error: () ->
      )

      std_msg_ajax(
        method: 'POST'
        url: "/escalations/api/v1/escalations/user_preferences/"
        data: {name: 'FileRepEntriesPerPage'}
        success: (response) ->
          response = JSON.parse(response)
          $('#file-rep-datatable').DataTable().page.len(response.entriesperpage).draw('page')
        error: () ->
      )



