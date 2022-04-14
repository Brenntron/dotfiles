$(document).ready ->

  hide_loading_gears()
  # TODO: move it to flexible method populate_dt_columns_from_settings(datatable, data_name)
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/user_preferences/"
    data: {name: 'SdrColumns'}
    success: (response) ->
      response = JSON.parse(response)
      if response?
        $.each response, (column, state) ->
          if state == true
            $("##{column}-checkbox").prop('checked', true)
            $('#sdr-disputes-index').DataTable().column("##{column}").visible true
          else
            $("##{column}-checkbox").prop('checked', false)
            $('#sdr-disputes-index').DataTable().column("##{column}").visible false
  )

  # pull entries per page setting
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/user_preferences/"
    data: {name: 'SdrEntriesPerPage'}
    success: (response) ->
      response = JSON.parse(response)
      if response?
        $('select[name="sdr-disputes-index_length"]').val(response.entries_per_page)
        $('#sdr-disputes-index').DataTable().page.len(response.entries_per_page).draw('page')
  )
$ ->
  initialize_sdr_disputes_datatable()

  $('#sdr-disputes-index_filter input').addClass('table-search-input');
  $('#sdr-disputes-index_filter label').addClass('table-search-label');

  # save entries per page setting
  $('#sdr-disputes-index').DataTable().on 'length.dt', (e, settings, len) ->
    data = {}
    data['entries_per_page'] = $('select[name="sdr-disputes-index_length"]').val()
    std_msg_ajax(
      url: "/escalations/api/v1/escalations/user_preferences/update"
      method: 'POST'
      data: {data, name: 'SdrEntriesPerPage'}
      dataType: 'json'
      success: (response) ->
  )

  $('.toggle-vis-sdr').each ->
    column = $('#sdr-disputes-index').DataTable().column($(this).attr('data-column'))
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

  # TODO: we could create universal method for this one too
  $('.toggle-vis-sdr').on "click", ->
    data = {}
    columns = ['priority', 'case-id', 'status', 'resolution', 'time-submitted',
               'age', 'assignee', 'case-origin', 'platform', 'dispute', 'current-rep',
               'rules', 'suggested-rep', 'submitter-type', 'contact-name', 'contact-email', 'submitter-org']

    data[column] = $("##{column}-checkbox").is(':checked') for column in columns

    std_msg_ajax(
      url: "/escalations/api/v1/escalations/user_preferences/update"
      method: 'POST'
      data: {data, name: 'SdrColumns'}
      dataType: 'json'
      success: (response) ->
      error: () ->
    )


window.initialize_sdr_disputes_datatable = () ->
  $('#sdr-disputes-index').DataTable(
    processing: true
    serverSide: true
    dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
    language: {
      search: '_INPUT_'
      searchPlaceholder: 'Search within table'
    }
    ajax:
      url: $('#sdr-disputes-index').data('source')
    pagingType: 'full_numbers'
    order: [[ 5, 'desc' ]]  # that's tmp default sorting column
    columnDefs: [
      { targets: [0,6], orderable: false } # remove sorting from age column
    ]
    columns: [
      {
        data:'case_id'
        width: '10px'
        render: (data, type, full, meta) ->
          return '<input type="checkbox" onclick="toggleRow(this)" name="cbox" class="sdr_dispute_check_box" id="cbox' + data + '" value="' + data + '"/>'
      }
      # placeholder for priority column
      {
        data: null
        orderable: false
        searchable: false
        sortable: false
        defaultContent: '<span></span>'
        width: '10px'
        render: ( data )-> ''
#          { is_important, was_dismissed } = data
#          if is_important == "true" && was_dismissed == "true"
#            return '<div class="container-important-tags ">' +
#              '<div class="esc-tooltipped is-important highlight-second-review" tooltip title="Important"></div>' +
#              '<div class="esc-tooltipped was-reviewed highlight-was-dismissed" tooltip title="Reviewed"></div>' +
#              '</div>'
#          else if is_important == "true" && was_dismissed == "false"
#            return '<span class="esc-tooltipped is-important highlight-second-review" tooltip title="Important"></span>'
#          else if is_important == "false" && was_dismissed == "true"
#            return '<span class="esc-tooltipped was-reviewed highlight-was-dismissed" tooltip title="Reviewed"></span>'
      }
      {
        width: '50px'
        data: 'case_id'
        render: (data, type, full, meta) ->
          return parseInt(data).pad(10)
      }
      {
        data: 'status'
        render: (data, type, full, meta) ->
          return "<span id=status_#{full.case_id}>" + data + '</span>'
      }
      { data: 'resolution' }
      {
        data: 'created_at'
        render: (data) ->
          if data
            return moment(data, "YYYY-MM-DD HH:mm").format("YYYY-MM-DD HH:mm")
          else
            return ''
      }
      {
        #age column
        width: '30px'
        render: (data, type, full, meta) ->
          { age, status } = full
          unless status == 'COMPLETED' || status == 'RESOLVED'
            if age.indexOf('hour') != -1
              hour = parseInt( age.split("h")[0] )
              if hour >= 3 && hour < 12
                age_class = 'ticket-age-over3hr'
              else if hour > 12
                age_class = 'ticket-age-over12hr'
            else if age.indexOf('minute') != -1
              age_class = ''
            else
              age_class = 'ticket-age-over12hr'
            return "<span class='#{age_class}'>#{age}</span>"
          # if status is "completed" or "resolved", no css class (orange/red) needed
          else
            return "<span>#{age}</span>"
      }
      {
        data: 'assignee'
        className: "alt-col assignee-col"
        render: (data, type, full, meta) ->
          if full.current_user == data
            return "<span id='owner_#{full.case_id}'> #{data} </span><button class='esc-tooltipped return-ticket-button inline-return-ticket-#{full.case_id}' title='Return ticket' onclick='return_sdr_dispute(#{full.case_id});'></button>"
          else if data == 'Vrt Incoming' || data == ""
            return "<span class='missing-data missing-data-index' id='owner_#{full.case_id}'>Unassigned</span> <span title='Assign to me' class='esc-tooltipped'><button class='take-ticket-button inline-take-dispute-#{full.case_id}' onClick='take_sdr_dispute(#{full.case_id})'/></button></span>"
          else
            return data
      }
      { data: 'source' }
      { data: 'platform' }
      { data: 'dispute' }
      #current_rep
      { data: null, render: ( data )-> '' }
      #rules
      { data: null, render: ( data )-> '' }
      #suggested_rep
      { data: null, render: ( data )-> '' }
      { data: 'submitter_type' }
      { data: 'contact_name' }
      { data: 'contact_email' }
      { data: 'submitter_org' }
    ]
  )

window.sdr_disputes_select_all_check_box = () ->
  $('.sdr_dispute_check_box').prop('checked', $('#sdr_disputes_check_box').prop('checked'))
  row = $('.sdr_dispute_check_box').parents('tr')
  if $('.sdr_dispute_check_box').prop('checked') == true
    $(row).addClass('selected')
  else
    $(row).removeClass('selected')

window.take_sdr_disputes = () ->
  dispute_ids = selected_sdr_disputes()

  if dispute_ids.length == 0
    std_msg_error('No Tickets Selected', ['Please select at least one ticket to assign.'])
    return

  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/sdr/disputes/take_disputes"
    data: { dispute_ids: dispute_ids }
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      for dispute_id in response.dispute_ids
        assign_sdr_dispute_on_me_on_view(dispute_id, response.user_display_name)
      std_msg_success('Tickets successfully assigned', [response.dispute_ids.length + ' have been assigned to ' + response.user_display_name])
    error: (error) ->
      std_msg_error('Assign Issue(s) Error', [
        'Failed to assign ' + dispute_ids.length + ' issue(s).',
        'Due to: ' + error.responseJSON.message
      ])
  )

window.take_sdr_dispute = (dispute_id) ->
  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/sdr/disputes/take_dispute/" + dispute_id
    data: {}
    dispute_id: dispute_id
    error_prefix: 'Error updating ticket'
    success: (response) ->
      assign_sdr_dispute_on_me_on_view(response.dispute_id, response.user_display_name)
  )

window.return_sdr_dispute = (dispute_id) ->
  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/sdr/disputes/return_dispute/" + dispute_id
    data: {}
    dispute_id: dispute_id
    error_prefix: 'Error updating ticket'
    success: (response) ->
      return_sdr_dispute_on_view(dispute_id)
  )

window.return_sdr_disputes = () ->
  dispute_ids = selected_sdr_disputes()

  if dispute_ids.length == 0
    std_msg_error('No Tickets Selected', ['Please select at least one ticket to return.'])
    return

  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/sdr/disputes/return_disputes"
    data: { dispute_ids: dispute_ids }
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      for dispute_id in response.dispute_ids
        return_sdr_dispute_on_view(dispute_id, response.user_display_name)
      std_msg_success('Tickets successfully returned', [response.dispute_ids.length + ' have been returned '])
    error: (error) ->
      std_msg_error('Return Issue(s) Error', [
        'Failed to return ' + dispute_ids.length + ' issue(s).',
        'Due to: ' + error.responseJSON.message
      ])
  )

window.selected_sdr_disputes = () ->
  return $('.sdr_dispute_check_box:checkbox:checked').map(() ->
    this.dataset['entryId']
    this.value
  ).toArray()

window.return_sdr_dispute_on_view = (dispute_id) ->
  $('.inline-return-ticket-' + dispute_id).replaceWith("<button class='esc-tooltipped take-ticket-button inline-take-dispute-#{dispute_id}' title='Assign this ticket to me' onclick='take_sdr_dispute(#{dispute_id});'></button>")
  $("#owner_#{dispute_id}").text("Unassigned").addClass('missing-data')
  $('#status_' + dispute_id).text("NEW")

window.assign_sdr_dispute_on_me_on_view = (dispute_id, user_name) ->
  $("#owner_#{dispute_id}").text(user_name).removeClass('missing-data')
  $('#status_' + dispute_id).text("ASSIGNED")
  $(".inline-take-dispute-#{dispute_id}").replaceWith("<button class='esc-tooltipped return-ticket-button inline-return-ticket-#{dispute_id}' title='Return ticket' onclick='return_sdr_dispute(#{dispute_id});'></button>")

window.hide_loading_gears = () ->
  loader = $('#sdr-loading-gear')
  $(this).bind(
    ajaxStart: () ->
      loader.removeClass('hidden')
    ajaxStop: () ->
      loader.addClass('hidden')
  )