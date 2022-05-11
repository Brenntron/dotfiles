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
    # TODO: add 'rules' and 'current-rep'
    columns = ['priority', 'case-id', 'status', 'resolution', 'time-submitted',
               'age', 'assignee', 'case-origin', 'platform', 'dispute',
               'suggested-rep', 'submitter-type', 'contact-name', 'contact-email', 'submitter-org']

    data[column] = $("##{column}-checkbox").is(':checked') for column in columns

    std_msg_ajax(
      url: "/escalations/api/v1/escalations/user_preferences/update"
      method: 'POST'
      data: {data, name: 'SdrColumns'}
      dataType: 'json'
      success: (response) ->
      error: () ->
    )

  $('.sdr-ticket-status-radio').click ->
    if $(this).is(':checked')
      wrapper = $(this).parent()
      $(wrapper).addClass('selected')

    if $(this).attr('id') == 'RESOLVED_CLOSED'
      $('#show-ticket-resolution-submenu').show()
      stat_comment = $('#ticket-non-res-submit').find('.ticket-status-comment')
      $('#ticket-non-res-submit').hide()
      $(stat_comment).val('')
    else
      $('#ticket-non-res-submit').show()
      res_comment = $('.resolution-comment-wrapper').find('.ticket-status-comment')
      $('.ticket-resolution-radio').prop('checked', false)
      $('#show-ticket-resolution-submenu').hide()
      $(res_comment[0]).val('')

  $('#sdr-advanced-search-button').click ->
    std_msg_ajax(
      method: 'GET'
      url: '/escalations/api/v1/escalations/sdr/disputes/autopopulate_advanced_search'
      success: (response) ->

        $('#user-list').empty()
        $('#status-list').empty()
        $('#submittertype-list').empty()
        $('#contactname-list').empty()
        $('#priority-list').empty()
        $('#contactemail-list').empty()
        $('#company-list').empty()
        $('#resolution-list').empty()

        $('#platform-input').selectize {
          persist: false
          create: false
          valueField: 'id',
          labelField: 'public_name',
          options: response.json.platforms
          onFocus: () ->
            window.sdr_toggle_selectize_layer(this, 'true')
          onBlur: () ->
            window.sdr_toggle_selectize_layer(this, 'false')
        }

        for user in response.json.case_owners
          $('#user-list').append '<option value=\'' + user.display_name + '\'></option>'

        for status in response.json.statuses
          $('#status-list').append '<option value=\'' + status + '\'></option>'

        for contact in response.json.contacts
          $('#contactname-list').append '<option value=\'' + contact.name + '\'></option>'

        for contact in response.json.contacts
          $('#contactemail-list').append '<option value=\'' + contact.email + '\'></option>'

        for company in response.json.companies
          $('#submitter-org-list').append '<option value=\'' + company.name + '\'></option>'

        for resolution in response.json.resolutions
          $('#resolution-list').append '<option value=\'' + resolution + '\'></option>'
          $('#resolution-list').append '<option value=\'' + resolution + '\'></option>'

        for priority in response.json.priorities
          $('#priority-list').append '<option value=\'' + priority + '\'></option>'

        $('#advanced-search-dropdown').show()
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
      data: build_sdr_data()
    pagingType: 'full_numbers'
    order: [[ 5, 'desc' ]]  # that's tmp default sorting column
    columnDefs: [
      {
        # remove sorting from age column
        targets: [0,6],
        orderable: false
      }
      {
        targets: [ 2 ]
        className: 'id-col'
      }
      {
        # Bolds the status
        targets: [ 3 ]
        className: 'font-weight-bold'
      }
    ]
    columns: [
      {
        data:'case_id'
        render: (data, type, full, meta) ->
          return '<input type="checkbox" onclick="toggleRow(this)" name="cbox" class="sdr_dispute_check_box" id="cbox' + data + '" value="' + data + '"/>'
      }
      {
        data: 'priority'
        searchable: false
        defaultContent: '<span></span>'
        render: ( data ) -> '<span class="bug-priority p-' + data + '">' + data + '</span>'
      }
      {
        data: 'case_id'
        render: (data, type, full, meta) -> "<a href='/escalations/sdr/disputes/#{data}'>#{parseInt(data).pad(10)}</a>"
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
        data: 'age'
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
      { data: null, visible: false, render: ( data )-> '' }
      #rules
      { data: null, visible: false, render: ( data )-> '' }
      #suggested_rep
      {
        data: 'suggested_disposition'
        render: (data) ->
          return "<span class='text-capitalize'>#{data}</span>"
      }
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

window.sdr_dispute_status_drop_down = (dispute_id) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

  $.ajax(
    url: "/escalations/api/v1/escalations/sdr/disputes/dispute_status/#{dispute_id}"
    method: 'GET'
    headers: headers
    data: {}
    dataType: 'json'
    success: (response) ->
      response = JSON.parse(response)
      status = response.status
      comment = response.comment

      $("#{status}").prop("checked", true)
      if comment?
        $('.ticket-status-comment').text(comment)
  )

window.sdr_show_page_edit_status = (dispute_id) ->
  statusName = $('input[name=dispute-status]:checked').val()
  dispute_id = $('#dispute_id').text()

  if statusName == 'RESOLVED_CLOSED'
    resolution = $("#show-edit-ticket-status-dropdown").find('input[name=dispute-resolution]:checked').val()
  else
    std_msg_error('No resolution selected', ['Please select a ticket resolution.'])

  data = {
    dispute_ids: [ dispute_id ]
    status: statusName
  }

  if resolution
    data.resolution = resolution
    data.comment = $('.ticket-resolution-comment').val()

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/sdr/disputes/set_disputes_status'
    method: 'POST'
    data: data
    error_prefix: 'Unable to update dispute.'
    success_reload: true
  )

window.sdr_toolbar_unassign_dispute = () ->
  single_id = $('#dispute_id').text()
  entry_ids = [single_id]

  data = {
    'dispute_ids': entry_ids
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/sdr/disputes/unassign_all'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error removing assignee')
  )

window.take_single_sdr_dispute = (id) ->
  dispute_ids = [ id ]

  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/sdr/disputes/take_disputes"
    data: { dispute_ids: dispute_ids }
    error_prefix: 'Error updating ticket.'
    success_reload: true
    success: (response) ->
      if response.dispute_ids.length > 0
        show_message('success', 'Ticket assignment has been updated!', 5)
        location.reload()
      else
        show_message('error', 'Ticket assnigment could not be updated.', 5)
        location.reload()
  )

window.sdr_toolbar_show_change_assignee = () ->
  singleId = $('#dispute_id').text()
  disputeIdArray = [singleId]
  new_assignee = $('#index_target_assignee option:selected').val()
  data = {
    'dispute_ids': disputeIdArray,
    'new_assignee': new_assignee
  }
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

  $.ajax(
    url: '/escalations/api/v1/escalations/sdr/disputes/change_assignee'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      show_message('success', 'Ticket assignment has been updated!', 5)
      window.location.reload()
    error: (response) ->
      show_message('error', 'Ticket assignment could not be updated.', 5)
      std_msg_error('No Tickets Selected', ['Select at least one ticket to assign to yourself.'])
  )

window.advanced_search_sdr_index_table = () ->
  # if form groups are hidden, wipe their values
  $('#sdr-disputes-advanced-search-form .form-group.hidden').find('input').val('')

  form = $('#sdr-disputes-advanced-search-form')

  platforms = $('#platform-input')[0].selectize? && $('#platform-input')[0].selectize.items
  platform_display = []
  if platforms.length
    for platform in platforms
      platform_display.push($('#platform-input')[0].selectize.options[platform].public_name)

  data = {
    id: form.find('input[id="caseid-input"]').val()
    customer_name: form.find('input[id="name-input"]').val()
    customer_email: form.find('input[id="email-input"]').val()
    company_name: form.find('input[id="submitter-org-input"]').val()
    sender_domain_entry: form.find('input[id="dispute-input"]').val()
    suggested_disposition: form.find('input[id="suggested-rep-input"]').val()
    case_owner: form.find('input[id="owner-input"]').val()
    status: form.find('input[id="status-input"]').val()
    priority: form.find('input[id="priority-input"]').val()
    resolution: form.find('input[id="resolution-input"]').val()
    platform_ids: form.find('input[id="platform-input"]').val()
    submitted_older: form.find('input[id="submitted-older-input"]').val()
    submitted_newer: form.find('input[id="submitted-newer-input"]').val()
    age_older: form.find('input[id="age-older-input"]').val()
    age_newer: form.find('input[id="age-newer-input"]').val()
    platforms: platform_display.join(', ')
  }

  localStorage.sdr_search_type = 'advanced'
  localStorage.sdr_search_name = form.find('input[name="search_name"]').val()
  localStorage.sdr_search_conditions = JSON.stringify(data)
  sdr_refresh_url()

# Prevent the many selectizes from running into each other
window.sdr_toggle_selectize_layer = (input, focus) ->
  input = input.$control_input[0]
  select_parent = $(input).parents('.form-control')[0]
  if focus == 'true'
    $(select_parent).css('z-index', '4')
  else
    $(select_parent).css('z-index', '2')

window.build_sdr_data = () ->
  data = {
    search_type: ''
    search_name: ''
  }

  if location.search != ''
    urlParams = new URLSearchParams(location.search);
    # if the location.search has value, it is a standard search
    data = {
      search_type : 'standard'
      search_name : urlParams.get('f')
    }
    sdr_refresh_localStorage()
  else if localStorage.sdr_search_type
    { sdr_search_type, sdr_search_name, sdr_search_conditions } = localStorage
    search_type = sdr_search_type
    search_name = sdr_search_name
    search_conditions = sdr_search_conditions

    if search_type == 'advanced'
      search_conditions = JSON.parse(search_conditions)

      data = {
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

  format_sdr_header(data)
  return data


window.sdr_refresh_url = (href) ->
  { sdr_search_type, sdr_search_name } = localStorage
  search_type = sdr_search_type
  search_name = sdr_search_name

  url_check = window.location.href.split('/escalations/sdr/disputes/')[0]
  new_url = '/escalations/sdr/disputes'

  if href != undefined
    localStorage.setItem('sdr_search_name', href)
    window.location.replace(new_url + href)

  if !href && typeof parseInt(url_check) == 'number'
    window.location.replace('/escalations/sdr/disputes')

window.sdr_refresh_localStorage = () ->
  localStorage.removeItem('sdr_search_type')
  localStorage.removeItem('sdr_search_name')
  localStorage.removeItem('sdr_search_conditions')

window.format_sdr_header = (data) ->
  container = $('#sdr_searchref_container')
  container.html("")
  if data != undefined && container.length > 0
    reset_icon = '<span id="refresh-filter-button" class="reset-filter esc-tooltipped" title="Clear Search Results" onclick="sdr_search_refresh()"></span>'
    { search_type, search_name } = data
    if search_type == 'standard'
      if search_name == 'all'
        reset_icon = ''
      new_header =
        '<div>' +
          '<span class="text-capitalize">' + search_name.replace(/_/g, " ") + ' tickets </span>' +
          reset_icon +
          '</div>'

    else if search_type == 'advanced'
      search_conditions = JSON.parse(localStorage.sdr_search_conditions)
      new_header = '<div>Results for Advanced Search ' + reset_icon + '</div>'
      for condition_name, condition of search_conditions
        if condition_name == 'platform_ids'
          continue
        if condition != ''
          condition_name = condition_name.replace(/_/g, " ").toUpperCase()
          if condition_name == 'CASE OWNER'
            condition_name = 'Assignee'
          if condition_name == 'COMPANY NAME'
            condition_name = 'SUBMITTER ORG'
          if condition_name == 'ID'
            condition_name = 'CASE ID'
          if condition_name == 'SENDER DOMAIN ENTRY'
            condition_name = 'DISPUTE'
          if condition_name == 'SUBMITED NEWER'
            condition_name = 'TIME SUBMITTED (NEWER)'
          if condition_name == 'SUBMITTED OLDER'
            condition_name = 'TIME SUBMITTED (OLDER)'

          condition_name_HTML = '<span class="search-condition-name text-uppercase">' + condition_name + ': </span>'

#          if typeof condition == 'object'
#            condition_HTML = '<span>' + condition.from  + ' - ' + condition.to+ '</span>'
#          else
          condition_HTML = '<span>' + condition + '</span>'

          container.append('<span class="search-condition">' + condition_name_HTML + condition_HTML + '</span>')
    else if search_type == 'named'
      new_header =
        '<div>Results for "' + search_name + '" Saved Search' +
          reset_icon +
          '</div>'
    else if search_type == 'contains'
      search_conditions = JSON.parse(localStorage.sdr_search_conditions)
      new_header =
        '<div>Results for "' + search_conditions.value + '" '+
          reset_icon +
          '</div>'
    else
      new_header = 'All Tickets'
    $('#sdr-index-title')[0].innerHTML = new_header

# on tooltip click
window.sdr_search_refresh = ()->
  sdr_refresh_localStorage()
  window.location.replace('/escalations/sdr/disputes')

# clean fields for advanced search
window.sdr_reset_search = ()->
  $('#sdr-disputes-advanced-search-form .form-group.hidden').find('input').val('')
  window.location.replace('/escalations/sdr/disputes')

window.sdr_build_contains_search = () ->
  search_string = $('#sdr-search .search-box').val().trim()
  if search_string == ''
    sdr_refresh_localStorage()
    sdr_refresh_url()
  else
    localStorage.sdr_search_type = 'contains'
    localStorage.sdr_search_name = ''
    localStorage.sdr_search_conditions = JSON.stringify({value:search_string})
  sdr_refresh_url()

window.sdr_build_named_search = (search_name) ->
  localStorage.sdr_search_type = 'named'
  localStorage.sdr_search_name = search_name
  localStorage.removeItem('sdr_search_conditions')
  sdr_refresh_url()