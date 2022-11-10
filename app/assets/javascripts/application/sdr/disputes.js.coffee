$(document).ready ->

  hide_loading_gears()
  # TODO: move it to flexible method populate_dt_columns_from_settings(datatable, data_name)
  if window.location.pathname == '/escalations/sdr/disputes'
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
  if window.location.pathname == '/escalations/sdr/disputes'
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
  if window.location.pathname == '/escalations/sdr/disputes'
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
          $('#user-list').append '<option value=\'' + user.cvs_username + '\'></option>'

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

  $('#sdr-resolution-selector input.sdr-ticket-resolution-radio').click (event)->
    fixed_fp_message_types = ['FIXED_FP_SUDDEN_SPIKE', 'FIXED_FP_DOMAIN_AGE', 'FIXED_FP_NEGATIVE_WEBREP']

    resolution_comments =
      'FIXED_FP_SUDDEN_SPIKE': 'The domain was impacted due to Talos sensors observing suspicious behavior typically indicative of spamming. This behavior is no longer observed and the reputation has been adjusted accordingly.'
      'FIXED_FP_DOMAIN_AGE': 'The domains were penalized by SDR due to a combination of domain registration and sending attributes prevalent in spam sending domains. The issue has been rectified and the domain reputation has been adjusted accordingly.'
      'FIXED_FP_NEGATIVE_WEBREP': 'This domain was penalized by SDR as it used to have a Untrusted Web Reputation score due to malicious or suspicious behavior. The issue has been rectified and the domain reputation has been adjusted accordingly.'
      'FIXED_FN': "Talos has concluded that the submission has been associated with recent spam campaigns; the submission's reputation has been decreased. This update will be publicly visible in the next 24 hours."
      'UNCHANGED': "Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission's reputation because it can negatively affect our customers."
    value = $(event.target.closest('input')).val()
    comment = resolution_comments[value] || ''
    if  value in fixed_fp_message_types
      $("input[name='dispute-resolution']").prop('checked', false)
      $('input#FIXED_FP').prop('checked', true)
    else
      $("input[name='dispute-preset-resolution']").prop('checked', false)

    $(".ticket-resolution-comment").html(comment)


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
          else if data == 'vrtincom' || data == ""
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

window.reload_sdr_dispute = () ->
  #$('#sdr-disputes-index').DataTable().ajax.reload(null, false)
  $('#sdr-disputes-index').DataTable().draw('page')
  #$('#sdr_disputes_check_box').prop('checked', false)


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
    show_message('error', 'No Tickets Selected. Please select at least one ticket to assign.', 5, '#alertMessage')
    return

  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/sdr/disputes/take_disputes"
    data: { dispute_ids: dispute_ids }
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      show_message('success', "#{response.dispute_ids.length} tickets have been assigned to #{response.username}.", 5, '#alertMessage')
      reload_sdr_dispute()
    error: (error) ->
      show_message('error', "Assign Issue(s) Error. Failed to assign #{dispute_ids.length} issue(s) due to: #{error.responseJSON.message}", 5, '#alertMessage')
  )

window.take_sdr_dispute = (dispute_id) ->
  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/sdr/disputes/take_dispute/" + dispute_id
    data: {}
    dispute_id: dispute_id
    error_prefix: 'Error updating ticket'
    success: (response) ->
      reload_sdr_dispute()
      show_message('success', "SDR Dispute #{dispute_id} has been assigned to #{response.username}.", 5, '#alertMessage')
  )

window.return_sdr_dispute = (dispute_id) ->
  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/sdr/disputes/return_dispute/" + dispute_id
    data: {}
    dispute_id: dispute_id
    error_prefix: 'Error updating ticket'
    success: (response) ->
      reload_sdr_dispute()
      show_message('success', "SDR Dispute #{dispute_id} has been returned.", 5, '#alertMessage')
    error: (error) ->
      show_message('error', [
        "Failed to return #{dispute_id} due to: #{error.responseJSON.message}"
      ], 5, '#alertMessage')
  )

window.return_sdr_disputes = () ->
  currentUser = $('input[name="current_user_id"]').val()
  dispute_ids = selected_sdr_disputes()

  if dispute_ids.length == 0
    show_message('error', 'No Tickets Selected. Please select at least one ticket to return.')
    return

  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/sdr/disputes/return_disputes"
    data: {
      dispute_ids: dispute_ids,
      current_user_id: currentUser
    }
    error_prefix: 'Error updating ticket.'
    success: (response) ->
      if response.dispute_ids.length == response.returned_ids.length
        show_message('success', "#{response.dispute_ids.length} disputes have been returned", 5, '#alertMessage')
      else if response.returned_ids.length == 0
        show_message('error', "No disputes have been returned. You can only return disputes assigned to you.", 5, '#alertMessage')
      else
        show_message('error', "#{response.returned_ids.length} disputes have been returned. #{response.dispute_ids.length - response.returned_ids.length} were not. You can only return disputes assigned to you.", 5, '#alertMessage')

      reload_sdr_dispute()
    error: (error) ->
      show_message('error', "Failed to return #{dispute_ids.length} issue(s) due to: #{error.responseJSON.message}", 5, '#alertMessage')
  )

window.selected_sdr_disputes = () ->
  return $('.sdr_dispute_check_box:checkbox:checked').map(() ->
    this.dataset['entryId']
    this.value
  ).toArray()

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
  else if statusName == 'ASSIGNED' && $('#dispute-assignee').hasClass('missing-data')
    std_msg_error('This ticket is unassigned', ['Please select an assignee.'])
    return

  data = {
    dispute_ids: [ dispute_id ]
    status: statusName
  }

  if resolution
    data.resolution = resolution
    data.comment = $('.ticket-resolution-comment').val()
  else
    data.comment = $('.ticket-status-comment').val()

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
      show_customer_cb('error', "Error removing assignee. #{response}", 5, '#alertMessage')
  )

window.take_single_sdr_dispute = (id) ->
  dispute_ids = [ id ]
  disputeAssignee = $('#dispute-assignee')
  if disputeAssignee.hasClass('missing-data')
    std_msg_ajax(
      method: 'PATCH'
      url: "/escalations/api/v1/escalations/sdr/disputes/take_disputes"
      data: { dispute_ids: dispute_ids }
      error_prefix: 'Error updating ticket.'
      success: (response) ->
        if response.dispute_ids.length > 0
          show_message('success', 'Ticket assignment has been updated.', 5, '#alertMessage')
          reload_sdr_dispute()
        else
          show_message('error', 'Ticket assnigment could not be updated.', 5, '#alertMessage')
    )
  else
    currentUser = $('input[name="current_user_id"]').val()
    $('#index_target_assignee').val(currentUser)
    window.sdr_toolbar_show_change_assignee()

window.sdr_toolbar_index_change_assignee = () ->
  disputeIdArray = $('.sdr_dispute_check_box:checkbox:checked').map(() ->
    Number(this.value)
  ).toArray()
  $('#index_change_assign').dropdown('toggle')
  sdr_change_assignee(disputeIdArray)

window.sdr_toolbar_show_change_assignee = () ->
  singleId = $('#dispute_id').text()
  disputeIdArray = [singleId]
  sdr_change_assignee(disputeIdArray)

sdr_change_assignee = (disputeIdArray) ->
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
      responseData = JSON.parse(response).data
      page = $('#sdr-disputes-index').DataTable().page

      if responseData.length > 0 && (data.dispute_ids.length == responseData.length)
        show_message('success', "#{responseData.length} ticket assignment(s) updated.", 5, '#alertMessage')
        reload_sdr_dispute()
      else if responseData.length > 0 && (data.dispute_ids.length != responseData.length)
        show_message('success', "#{responseData.length} ticket assignment(s) updated, but not every ticket was updated. Closed tickets cannot change their assignee", 5, '#alertMessage')
        reload_sdr_dispute()
      else
        show_message('error', 'No tickets updated. Closed tickets cannot change their assignee.', 5, '#alertMessage')
    error: (error) ->
      show_message('error', "Change Issue(s) Error: #{error.responseJSON.message}", 5, '#alertMessage')
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
      else if search_name == 'my_disputes'
        search_name = 'my'
      else if search_name == 'team_disputes'
        search_name = "my team's"

      new_header = "<div><span class='text-capitalize'>#{search_name.replace(/_/g, " ")} tickets</span>#{reset_icon}</div>"
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

window.export_sdr_all = () ->
  form = document.getElementById("sdr-disputes-export-form")
  data = build_sdr_data()

  if 'advanced' == data.search_type
    data.search_name = null
  data_json = JSON.stringify(data)
  $('#index-export-data-input').val(data_json)
  form.onsubmit = ""
  form.submit()
  form.onsubmit = () ->
    return false

window.export_sdr_selected = () ->
  data = build_sdr_data()
  data.selected_cases = $('.sdr_dispute_check_box:checked').map((i, el) => el.value).get()

  if data.selected_cases.length <= 0
    std_msg_error('Error: Nothing selected.',"", reload: false)
    return false
  if 'advanced' == data.search_type
    data.search_name = null
  data_json = JSON.stringify(data)
  $('#index-export-data-input').val(data_json)
  document.getElementById("sdr-disputes-export-form").onsubmit = ""

window.sdr_index_edit_ticket_status = () ->
    dropdown = $('#sdr-index-edit-ticket-status-dropdown').parent()

    if ($('.sdr_dispute_check_box:checked').length > 0)
# Select Status
      $('.sdr-ticket-status-radio-label').click ->
        radio_button = $(this).prev('.sdr-ticket-status-radio')
        $(radio_button[0]).trigger('click')
        if $(radio_button).attr('id') == 'RESOLVED_CLOSED'
          $('#sdr-index-dispute-resolution-submenu').show()
          stat_comment = $('#ticket-non-res-submit').find('.ticket-status-comment')
          $('#ticket-non-res-submit').hide()
          $(stat_comment).val('')
        else
          $('#ticket-non-res-submit').show()
          res_comment = $('.resolution-comment-wrapper').find('.ticket-status-comment')
          $('.ticket-resolution-radio').prop('checked', false)
          $('#sdr-index-dispute-resolution-submenu').hide()
          $(res_comment[0]).val('')

      $('.sdr-ticket-status-radio').click ->
        all_stat_radios = $('#sdr-index-edit-ticket-status-dropdown').find('.status-radio-wrapper')
        if $(this).is(':checked')
          wrapper = $(this).parent()
          $(all_stat_radios).removeClass('selected')
          $(wrapper).addClass('selected')
        if $(this).attr('id') == 'RESOLVED_CLOSED'
          $('#sdr-index-dispute-resolution-submenu').show()
          stat_comment = $('#ticket-non-res-submit').find('.ticket-status-comment')
          $('#ticket-non-res-submit').hide()
          $(stat_comment).val('')
        else
          $('#ticket-non-res-submit').show()
          res_comment = $('.resolution-comment-wrapper').find('.ticket-status-comment')
          $('.ticket-resolution-radio').prop('checked', false)
          $('#sdr-index-dispute-resolution-submenu').hide()
          $(res_comment[0]).val('')
    else
      std_msg_error('No rows selected', ['Please select at least one row.'])

window.sdr_index_change_ticket_status = () ->
  checkboxes = $('#sdr-disputes-index').find('.sdr_dispute_check_box')
  checked_dispute_ids = []
  comment = ''
  dropdown = $('#sdr-index-edit-ticket-status-dropdown').parent()
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  resolution = ""
  status = $('#sdr-index-edit-ticket-status-dropdown').find('.sdr-ticket-status-radio:checked').val()
  successfully_closed_disputes = []

  $(checkboxes).each ->
    if $(this).is(':checked')
      dispute_id = $(this).val()
      checked_dispute_ids.push(dispute_id)

  if status == 'RESOLVED_CLOSED' && $('#sdr-index-edit-ticket-status-dropdown').find('.sdr-ticket-resolution-radio').is(':checked')
    resolution = $('#sdr-index-edit-ticket-status-dropdown').find('.sdr-ticket-resolution-radio:checked').val()
    comment = $('.resolution-comment-wrapper').find('.ticket-resolution-comment').val()
  else if status == 'RESOLVED_CLOSED'
    show_message('error', 'No resolution selected. Please select a ticket resolution.', 5, '#alertMessage')
    return
  else if status == 'ASSIGNED' && $('#dispute-assignee').hasClass('missing-data')
    show_message('error', 'This ticket is unassigned. Please select an assignee.', 5, '#alertMessage')
    return
  else
    comment = $('.non-resolution-submit-wrapper').find('.ticket-status-comment').val()

  dropdown.dropdown('toggle')

  if comment
    data = {
      comment: comment,
      dispute_ids: checked_dispute_ids,
      resolution: resolution,
      status: status
    }

    $.ajax(
      url: '/escalations/api/v1/escalations/sdr/disputes/set_disputes_status'
      method: 'POST'
      headers: headers
      data: data
      success: (response) ->
        $('.ticket-status-comment').val('')
        show_message('success', 'Ticket status has been updated.', 5, '#alertMessage')
        reload_sdr_dispute()
      error: (response) ->
        show_message('error', "Error Updating Status. #{response}", 5, '#alertMessage')
    )
  else
    show_message('error', "Ticket status can't be changed without a comment.", 5, '#alertMessage')

