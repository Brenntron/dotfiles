assigned_timeout_id = ''

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

  # Show page resolution select
  $('.show-action .sdr-ticket-status-radio').click ->
    if $(this).is(':checked')
      wrapper = $(this).parent()
      $('.show-action .status-radio-wrapper').removeClass('selected')
      $(wrapper).addClass('selected')

    if $(this).attr('id') == 'RESOLVED_CLOSED'
      $('#show-ticket-resolution-submenu').show()
      stat_comment = $('#ticket-non-res-submit').find('.ticket-status-comment')
      $('#ticket-non-res-submit').hide()
      $(stat_comment).val('')
      # check first resolution checkbox (and Fixed-FP parent) if none checked after opening
      if !($("input.ticket-resolution-radio").is(':checked'))
        $('input#FIXED_FP').prop('checked', true)
        $('#FIXED_FP_SUDDEN_SPIKE').prop('checked', true)
        is_customer = check_for_customer_show_page_sdr()
        populate_resolved_sdr_templates('Fixed - FP: Sudden Spike', is_customer)

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

        for submitter_type in ["CUSTOMER", "NON-CUSTOMER", "Internal"]
          $('#submittertype-list').append '<option value=\'' + submitter_type + '\'></option>'

        $('#advanced-search-dropdown').show()
    )
    # populate SDR search is advanced search is open
    if localStorage.sdr_search_type == 'advanced' && localStorage.sdr_search_conditions
      search_conditions = JSON.parse(localStorage.sdr_search_conditions)
      $('#caseid-input').val(search_conditions.id)
      $('#name-input').val(search_conditions.customer_name)
      $('#email-input').val(search_conditions.customer_email)
      $('#submitter-org-input').val(search_conditions.company_name)
      $('#dispute-input').val(search_conditions.sender_domain_entry)
      $('#suggested-rep-input').val(search_conditions.suggested_disposition)
      $('#owner-input').val(search_conditions.case_owner)
      $('#status-input').val(search_conditions.status)
      $('#priority-input').val(search_conditions.priority)
      $('#resolution-input').val(search_conditions.resolution)
      $('#submitter-input').val(search_conditions.submitter_type)
      $('#platform-input')[0].selectize.setValue(search_conditions.platforms.split(', '))
      $('#submitted-older-input').val(search_conditions.submitted_older)
      $('#submitted-newer-input').val(search_conditions.submitted_newer)
      $('#age-older-input').val(search_conditions.age_older)
      $('#age-newer-input').val(search_conditions.age_newer)

  assemble_sdr_response_templates = (templates, customer_footer) ->
    resolution_select = $('#sdr-resolution-message-template-select.resolution-message-template-select')
    resolution_select.empty()
    is_customer = false

    if templates.length == 0
      resolution_select.val ''
      $('.ticket-resolution-description').text ''
      $('.ticket-resolution-comment').val ''

    $(templates).each (index, template) ->
      #append customer footer to saved message
      if customer_footer != ''
        customer_message = template.body + ' ' + customer_footer
        is_customer = true
      else customer_message = template.body

      template_option = $("<option class='sdr-resolution-template-option'></option>")
      $(template_option).val template.name
      $(template_option).text template.name
      $(template_option).attr('data-body', customer_message )
      $(template_option).attr('data-description', template.description )
      resolution_select.append template_option

      #show first option as body and description
      if index == 0
        $('.ticket-resolution-description').text template.description
        $('.ticket-resolution-comment').val customer_message
        resolution_select.attr('data-has-footer', is_customer)

  window.populate_resolved_sdr_templates = (resolution_type, is_customer) ->

    get_resolution_templates_by_resolution('sdr', resolution_type).then (response) ->
      templates = JSON.parse response
      customer_footer = ''

      if is_customer == true
        #fetch customer footer to append to message if customer ticket
        get_resolution_templates_by_resolution('sdr', 'Customer Footer').then (customer_footer_response) ->
          if customer_footer_response.length > 0
            customer_footer = JSON.parse customer_footer_response
            if customer_footer[0]?
              customer_footer = customer_footer[0].body
            assemble_sdr_response_templates(templates, customer_footer)
      else
        assemble_sdr_response_templates(templates, customer_footer)

  # Resolution status change - Index and Show page
  $('#sdr-resolution-selector .sdr-ticket-resolution-radio').change (event)->
    fixed_fp_message_types = ['Fixed - FP: Sudden Spike', 'Fixed - FP: Domain Age', 'Fixed - FP: Negative Webrep']

    resolution_type = $(event.target.closest('input')).attr('data-saved-resolution-type')
    #uncheck Fixed - FP choices if clicking outside Fixed - FP
    if resolution_type in fixed_fp_message_types
      $("input[name='dispute-resolution']").prop('checked', false)
      $('input#FIXED_FP').prop('checked', true)
    else
      $("input[name='dispute-preset-resolution']").prop('checked', false)

    #check if on index table or show page, then check if customer
    if $('.escalations--sdr--disputes-controller.show-action').length > 0
      is_customer = check_for_customer_show_page_sdr()
    else
      is_customer = check_for_customer_checkbox_sdr()
    populate_resolved_sdr_templates(resolution_type, is_customer)


window.check_for_customer_show_page_sdr = () ->
  submitter_type = $(".submitter-type-wrapper p").text().toLowerCase()
  if submitter_type == 'customer'
    is_customer = true
  else
    is_customer = false
  is_customer

window.check_for_customer_checkbox_sdr = () ->
  #show customer message if any checked rows are for customers
  checkboxes = $('#sdr-disputes-index').find('.sdr_dispute_check_box:checked')
  table = $('#sdr-disputes-index').DataTable()
  is_customer = false
  $(checkboxes).each ->
    tr = $(this).closest('tr')
    row = table.row(tr)
    if row.data().submitter_type.toLowerCase() == 'customer'
      is_customer = true
  is_customer

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
    stateSave: true
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
      {
        data: 'dispute'
        render: (data) ->
          return "<div class='text-wrap'>#{data}</div>"
      }
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
  $('#sdr-disputes-index').DataTable().draw('page')


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
      $assignee_element = $('#dispute-assignee')

      $assignee_element.text('Unassigned')
      $assignee_element.addClass('missing-data')

      $('.take-ticket-button').attr('disabled', false)
      $('#index_change_assign').attr('disabled', false)
      $('.return-ticket-button').attr('disabled', true)
      $('.ticket-owner-unassign-button').attr('disabled', true)
      $('#show-edit-ticket-status-button').text('NEW')

      clearTimeout(assigned_timeout_id)
      $('#assignedAlert').addClass('hidden') if !$('#assignedAlert').hasClass('hidden')
      $('#unassignedAlert').removeClass('hidden') if $('#unassignedAlert').hasClass('hidden')
      $('.assigned-check').removeClass('hidden') if $('.assigned-check').hasClass('hidden')
      assigned_timeout_id = setTimeout () ->
        $('.assigned-check').addClass('hidden')
        $('#unassignedAlert').addClass('hidden')
      , 5000
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

window.sdr_dispute_status_drop_down = () ->
  #deselect all statuses
  $('.status-radio-wrapper').removeClass 'selected'
  $('.sdr-ticket-status-radio').prop("checked", false)

  #close comment dropdowns
  $('.sdr-non-resolution-submit-wrapper').hide()
  $('#show-ticket-resolution-submenu').hide()

  #select current status in dropdown (NEW is not an option so that won't select anything)
  status = $('#show-edit-ticket-status-button').text().trim()
  radio = $(".sdr-ticket-status-radio[data-status='#{status}'] ")
  radio.prop("checked", true)
  wrapper = radio.parent()
  wrapper.addClass('selected')

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
      parsed_response = JSON.parse response
      if parsed_response.status == 'success'
        $assignee_element = $('#dispute-assignee')

        $assignee_element.text('Unassigned')
        $assignee_element.addClass('missing-data')
        $('.take-ticket-button').attr('disabled', false)
        $('#index_change_assign').attr('disabled', false)
        $('.ticket-owner-unassign-button').attr('disabled', true)
        $('.return-ticket-button').attr('disabled', true)
        $('#show-edit-ticket-status-button').text('NEW')

        clearTimeout(assigned_timeout_id)
        $('#assignedAlert').addClass('hidden') if !$('#assignedAlert').hasClass('hidden')
        $('#unassignedAlert').removeClass('hidden') if $('#unassignedAlert').hasClass('hidden')
        $('.assigned-check').removeClass('hidden') if $('.assigned-check').hasClass('hidden')
        assigned_timeout_id = setTimeout () ->
          $('.assigned-check').addClass('hidden')
          $('#unassignedAlert').addClass('hidden')
        , 5000
      else
        show_message('error', 'Ticket assingment could not be updated.', 5, '#alertMessage')
    error: (response) ->
      parsed_response = JSON.parse response
      show_customer_cb('error', "Error removing assignee. #{parsed_response}", 5, '#alertMessage')
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
          $assignee_element = $('#dispute-assignee')
          $assignee_element.text(response.username)

          $('.take-ticket-button').attr('disabled', true)
          $('#index_change_assign').attr('disabled', false)
          $('.return-ticket-button').attr('disabled', false)
          $('.ticket-owner-unassign-button').attr('disabled', false)
          $assignee_element.removeClass('missing-data') if $assignee_element.hasClass('missing-data')
          $('#show-edit-ticket-status-button').text('ASSIGNED')

          clearTimeout(assigned_timeout_id)
          $('#unassignedAlert').addClass('hidden') if !$('#unassignedAlert').hasClass('hidden')
          $('#assignedAlert').removeClass('hidden') if $('#assignedAlert').hasClass('hidden')
          $('.assigned-check').removeClass('hidden') if $('.assigned-check').hasClass('hidden')
          assigned_timeout_id = setTimeout () ->
            $('.assigned-check').addClass('hidden')
            $('#assignedAlert').addClass('hidden')
          , 5000
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
  sdr_change_assignee(disputeIdArray, 'index')

window.sdr_toolbar_show_change_assignee = () ->
  singleId = $('#dispute_id').text()
  disputeIdArray = [singleId]
  sdr_change_assignee(disputeIdArray, 'show')

sdr_change_assignee = (disputeIdArray, page) ->
  new_assignee = $('#index_target_assignee option:selected').val()
  data = {
    'dispute_ids': disputeIdArray,
    'new_assignee': new_assignee
  }
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $('#index_change_assign').dropdown('toggle')

  $.ajax(
    url: '/escalations/api/v1/escalations/sdr/disputes/change_assignee'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      responseData = JSON.parse(response).data
      page = $('#sdr-disputes-index').DataTable().page

      if responseData.length > 0
        success_message = ''

        if data.dispute_ids.length == responseData.length
          success_message = "#{responseData.length} ticket assignment(s) updated."
        else
          success_message = "#{responseData.length} ticket assignment(s) updated, but not every ticket was updated. Closed tickets cannot change their assignee"

        if page is 'index'
          reload_sdr_dispute()

          show_message('success', success_message, 5, '#alertMessage')
        else
          current_user_id = $('input[name="current_user_id"]').val()
          user_id = $('#index_target_assignee option:selected').val()
          new_assignee = $('#index_target_assignee option:selected').text()
          is_assignee = parseInt(current_user_id) is parseInt(user_id)
          $assignee_element = $('#dispute-assignee')

          $assignee_element.text(new_assignee)

          if is_assignee
            $('.return-ticket-button').attr('disabled', false)
            $('.take-ticket-button').attr('disabled', true)
            $('.ticket-owner-unassign-button').attr('disabled', true)
          else
            $('.return-ticket-button').attr('disabled', true)
            $('.take-ticket-button').attr('disabled', false)
            $('.ticket-owner-unassign-button').attr('disabled', false)

          $assignee_element.removeClass('missing-data') if $assignee_element.hasClass('missing-data')
          $('#show-edit-ticket-status-button').text('ASSIGNED')

          clearTimeout(assigned_timeout_id)
          $('#unassignedAlert').addClass('hidden') if !$('#unassignedAlert').hasClass('hidden')
          $('#assignedAlert').removeClass('hidden') if $('#assignedAlert').hasClass('hidden')
          $('.assigned-check').removeClass('hidden') if $('.assigned-check').hasClass('hidden')
          assigned_timeout_id = setTimeout () ->
            $('.assigned-check').addClass('hidden')
            $('#assignedAlert').addClass('hidden')
          , 5000
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
    submitter_type: form.find('input[id="submitter-input"]').val()
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

  else
    data = {
      search_type: 'standard'
      search_name: 'unassigned'
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
    if search_name == 'unassigned' && location.search == ''
      reset_icon = ''
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

# index edit status button press
window.sdr_index_edit_ticket_status = () ->
    if ($('.sdr_dispute_check_box:checked').length > 0)

      # If menu is being re-opened, check if customer status has changed for checked rows and reload dropdown if it has
      if $('#sdr-index-dispute-resolution-submenu .sdr-ticket-resolution-radio:checked').length > 0
        is_customer = check_for_customer_checkbox_sdr()
        current_resolution = $('#sdr-index-dispute-resolution-submenu .sdr-ticket-resolution-radio:checked').siblings('.ticket-res-radio-label').text()
        current_resolution = current_resolution.replace('Fixed - FP', 'Fixed - FP: ') #need to format the top three options in a specific way
        customer_loaded_in_form = $('#sdr-resolution-message-template-select').attr('data-has-footer')
        if is_customer == true && customer_loaded_in_form == 'false' || is_customer == false && customer_loaded_in_form == 'true'
          #reload form data to add/remove customer footer
          populate_resolved_sdr_templates(current_resolution, is_customer)
          $('#sdr-resolution-message-template-select').attr('data-has-footer', is_customer)

      # Select Status
      $('.sdr-ticket-status-radio').change ->
        radio_button = $(this)
        all_stat_radios = $('#sdr-index-edit-ticket-status-dropdown').find('.status-radio-wrapper')
        wrapper = $(this).parent()
        $(all_stat_radios).removeClass('selected')
        $(wrapper).addClass('selected')

        if $(radio_button).attr('id') == 'RESOLVED_CLOSED'
          $('#sdr-index-dispute-resolution-submenu').show()
          stat_comment = $('#ticket-non-res-submit').find('.ticket-status-comment')
          $('#ticket-non-res-submit').hide()
          $(stat_comment).val('')
          $('input#FIXED_FP').prop('checked', true)
          $('#FIXED_FP_SUDDEN_SPIKE').prop('checked', true)

          #show customer message if any checked rows are for customers
          is_customer = check_for_customer_checkbox_sdr()
          populate_resolved_sdr_templates('Fixed - FP: Sudden Spike', is_customer)

        else
          $('#ticket-non-res-submit').show()
          res_comment = $('.resolution-comment-wrapper').find('.ticket-status-comment')
          $('.ticket-resolution-radio').prop('checked', false)
          $('#sdr-index-dispute-resolution-submenu').hide()
          $(res_comment[0]).val('')

    else
      std_msg_error('No rows selected', ['Please select at least one row.'])

      #reset the resolution dropdown if it is already populated
      if $('.sdr-ticket-status-radio').prop('checked', true)
        $('.sdr-ticket-resolution-radio').prop('checked', false)
        $('.sdr-ticket-status-radio').prop('checked', false)
        $('#sdr-index-dispute-resolution-submenu').hide()
        $('#ticket-non-res-submit').hide()
        $('.status-radio-wrapper').removeClass 'selected'

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

