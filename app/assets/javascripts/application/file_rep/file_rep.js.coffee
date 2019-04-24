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
      {
        data: 'reversing_labs_score'
        render: (data, type, full, meta) ->
          if data
            return '<span class="score-col text-center">' + data + ' / ' + full['reversing_labs_count'] + '</span>'
          else
            return ''
      }
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


$ ->
  ## Create detection form dialog
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

    comment = $('#new-amp-detection-comment').val()

    # Grab sha data
    # From show page only one sha can be submitted
    if page == 'show'
      # Get sha
      sha = $('#sha256_hash')[0].innerText

    # From index several shas could be submitted (from the users perspective)
    else if page == 'index'
      if $('.dispute_check_box:checked').length < 1
        std_msg_error('No Tickets Selected', ['Please select at least one ticket to submit detection for.'])
      else

      sha = []
      # Get all checked checkboxes
      $('.dispute_check_box:checked').each ->
        sha_val =  $(this).attr('data-sha')
        sha.push(sha_val)


      # Marlin - I don't know how you want to handl this. We can only send one sha at a time,
      # but we can set up the back end to send one after another with the same detection setting.
      # This preps for either case, and provides the sha(s) and the detection info separately.

      console.log sha
      console.log detection_array
    else
      alert('Where are you? How did you trigger this? Stahp it.')

    return false


