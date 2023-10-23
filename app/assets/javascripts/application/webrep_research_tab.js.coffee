$ ->
  # go back to the last tab after reload

  $('a[data-toggle="tab"]').on 'shown.bs.tab', (e) ->
    localStorage.setItem 'lastTab', $(this).attr('id')
    return

  $('.reputation-research-search-wrapper a').on 'click', () ->
    hide_toolbar()

  hide_toolbar = () ->
  # hides toolbar depending on which tab in bulk research panel is open
    tab = window.location.href
    if tab.includes('quick')
      $('#research-page-toolbar').hide()
      $('.research_results').hide()
    else
      $('#research-page-toolbar').show()
      $('.research_results').show()

  $(document).on 'ready page:load', (e) ->
    hide_toolbar()
    lastTab = localStorage.getItem('lastTab')
    if lastTab
      $('#' + lastTab).tab('show');
    else
      $('#communication-tab-link').tab('show')
    return

$ ->
  $('#edit-dispute-entry-button').click ->
    if ($('.dispute_check_box:checked').length > 0)
      $('.edit-entries-buttons').removeClass('hidden')
      $('.dispute_check_box').each ->
        if $(this).prop('checked')
          entry_row = $(this).parents('.research-table-row')[0]
          $(entry_row).addClass('editing-row')
          editable_data = $(entry_row).find('.entry-data')
          input =  $(entry_row).find('.table-entry-input')
          $(editable_data).each ->
            $(this).hide()
          $(input).each ->
            $(this).show()
          first_item = $(editable_data)[0]
          $(first_item).next('.table-entry-input')[0].focus()
    else
      std_msg_error('No rows selected', ['Select at least one entry to edit'])

  $('.dispute_check_box').on 'click', (e) ->
    if $(this).not(":checked") && $('.cancel-changes').is(":visible")
      if confirm "Cancel editing?"
        $('.cancel-changes').click()
      else
        e.preventDefault()

  $('#add-to-ticket-button').on 'click', ()->
    new_val = ''
    html_val = ''
    $('#disputes-research-table .dispute_check_box:checked').each ->
      tr = $( this ).closest('tr')
      url = $(tr).find('.entry-data-content').text().trim()
      html_val += "<div class='uneditable_urls'> #{url} </div>"
      if new_val != ''
        new_val += "&#10 #{url}"
      else
        new_val = url
    $('#research-page-toolbar .ips_urls').html( new_val.trim() )
    $('#research-page-toolbar .ips_urls_div').html( html_val )

  $('.cancel-changes').click ->
    $('.editing-row').each ->
      editing_inputs = $(this).find('.table-entry-input')
      $(editing_inputs).each ->
        if $(this).attr('type') == 'text'
          entry_wrapper = $(this).prev('.entry-data')
          entry_data = $(entry_wrapper[0]).text()
          new_data = $(this).val()
          unless new_data == entry_data
            new_data = entry_data
          $(this).val(new_data)
          $(entry_wrapper[0]).show()
          $(this).hide()

        else if $(this).is('button')
          entry_parent = $(this).parent('.dropdown')
          entry_wrapper = $(entry_parent).prev('.entry-data')
          entry_data = $(entry_wrapper).text()
          new_data = $(this).text()
          unless new_data == entry_data
            new_data = entry_data
          $(this).text(new_data)
          $(entry_wrapper[0]).show()
          $(this).hide()
      $(this).removeClass('editing-row')
      $('.edit-entries-buttons').addClass('hidden')

  #   Need to add save function after editing.
  #        When they hit save it should send the update to the ticket,
  #      populate everywhere / reload the page,
  #        and set the entry span to match the content of the input
  #


  # Inline Edit Button
  $('.inline-edit-entry-button').click ->
    entry_row = $(this).parents('.research-table-row')[0]
    $(entry_row).addClass('editing-row')
    editable_data = $(entry_row).find('.entry-data')
    input =  $(entry_row).find('.table-entry-input')
    $(editable_data).each ->
      $(this).hide()
    $(input).each ->
      $(this).show()
    first_item = $(editable_data)[0]
    $(first_item).next('.table-entry-input')[0].focus()
    if $('.edit-entries-buttons').hasClass('hidden')
      $('.edit-entries-buttons').removeClass('hidden')



  # Edit resolved host IPs
  $('.inline-edit-ip-button').click ->
    edit_ip_query_functions(this, 'edit')

  # Save edits to resovled host IPs
  $('.inline-save-ip-button').click ->
    edit_ip_query_functions(this, 'save')

  # Cancel edits to resolved host IPs
  $('.inline-cancel-ip-button').click ->
    edit_ip_query_functions(this, 'cancel')


  window.edit_ip_query_functions = (button, action, page) ->
    # Get our DOM elements
    entry_row = $(button).parents('.research-table-row')[0]
    entry_uri = $.trim($($(entry_row).find('.entry-data-content')[0]).text())
    ip_input  = $(entry_row).find('.table-ip-input')[0]
    ip_data   = $(entry_row).find('.entry-resolved-ip-content')[0]
    ip_edit   = $(entry_row).find('.inline-edit-ip-button')[0]
    ip_save   = $(entry_row).find('.inline-save-ip-button')[0]
    ip_cancel = $(entry_row).find('.inline-cancel-ip-button')[0]
    old_ips   = $(ip_data).text()
    new_ips   = $(ip_input).val()

    if action == 'edit'
      $(ip_edit).hide()
      $(ip_data).hide()
      $(ip_input).show()
      $(ip_save).show()
      $(ip_cancel).show()
      $(ip_input).focus()

    else
      $(ip_cancel).hide()
      $(ip_save).hide()
      $(ip_input).hide()
      $(ip_edit).show()
      $(ip_data).show()

      if action == 'save'
        if $.trim(old_ips) != new_ips
          ip_arry = cleanse_array(new_ips)
          # show the prettier cleansed array as a string
          ip_str = ip_arry.join(', ')
          $(ip_data).text(ip_str)
          $(ip_input).val(ip_str)
          # Get query data & save to db
          query_uri_plus_ip(entry_uri, ip_arry, entry_row)
        else
          alert 'no changes made!'

      if action == 'cancel'
        if $.trim(old_ips) != new_ips
          $(ip_input).val(old_ips)


  ## Inline Edit Status
  $('.escalations--webrep--disputes-controller.show-action .status-cell .radio-label').click ->
    radio_button = $(this).prev('input[type="radio"]')
    $(radio_button[0]).prop('checked', true)

  # Expand All Rows
  $('#expand-all-rows').click ->
    $('.research-table-row-wrapper').each ->
      expand_inline_toggle = $(this).find('.expand-row-button-inline')
      unless $(expand_inline_toggle[0]).hasClass('shown')
        $(expand_inline_toggle).addClass('shown')
      expandable_row = $(this).find('.nested-data-row')[0]
      $(expandable_row).show()

  # Collapse All Rows
  $('#collapse-all-rows').click ->
    $('.research-table-row-wrapper').each ->
      expand_inline_toggle = $(this).find('.expand-row-button-inline')
      if $(expand_inline_toggle[0]).hasClass('shown')
        $(expand_inline_toggle).removeClass('shown')
      expandable_row = $(this).find('.nested-data-row')[0]
      $(expandable_row).hide()

  #  Expand / Collapse the expandable row (inline button)
  $('.expand-row-button-inline').click ->
    expand_button = $(this)
    entry_row = $(this).parents('.research-table-row')[0]
    nested_row = $(entry_row).find('.nested-data-row')[0]
    $(nested_row).toggle()
    $(expand_button).toggleClass('shown')

  ## WL/BL Form manipulation
  $('.wl-bl-list-inline').click ->
    page = ''
    if $('#wlbl_adjust_entries_index').length > 0
      page = $('#wlbl_adjust_entries_index')
    else if $('#wlbl_adjust_entries').length > 0
      page = $('#wlbl_adjust_entries')

    wlbl_entries = $(page).find('.wlbl-dropdown-row')
    wlbl_submit = $(page).find('.dropdown-submit-button')
    if wlbl_entries.length > 0 && $('.wl-bl-list-inline:checked').length > 0
      wlbl_submit.attr('disabled', false)
    else
      wlbl_submit.attr('disabled', true)


  ## Bulk submission of WL/BL changes (works on index, research page, and research tab of show page)
  window.bulk_adjust_wlbl = (page) ->
    data = {}
    ip_uris = []
    list_types = []
    list_types = $('.wl-bl-list-inline:checkbox:checked').map(() -> this.value).toArray()
    wlbl_comment = ''
    dropdown = ''

    if $('.wl-bl-list-inline:checkbox:checked').length > 0

      if page == 'index'
        dropdown = $('#wlbl_adjust_entries_index')
      else if page == 'show' || page == 'research'
        dropdown = $('#wlbl_adjust_entries')

      entries = $(dropdown).find('.wlbl-entry-content')
      wlbl_comment = $(dropdown).find('.adjust-wlbl-input').val()

      if $(entries).length > 0
        $(entries).each ->
          entry = $(this).text()
          ip_uris.push(entry)

      data = {ip_uris: ip_uris, list_types: list_types, note: wlbl_comment}

      if $('#wlbl-remove').prop('checked') == true
        std_msg_ajax(
          url: '/escalations/api/v1/escalations/webrep/disputes/bulk_rule_ui_wlbl_remove'
          method: 'POST'
          data: data
          success: (response) ->
            std_msg_success("The following entries have been removed from " + list_types, ip_uris)
          error: (response) ->
            std_api_error(response, 'Error retrieving WL/BL Data')
        )
      else if $('#wlbl-add').prop('checked') == true
        std_msg_ajax(
          url: '/escalations/api/v1/escalations/webrep/disputes/bulk_rule_ui_wlbl_add'
          method: 'POST'
          data: data
          success: (response) ->
            std_msg_success("The following entries have been added to " + list_types, ip_uris)
          error: (response) ->
            std_api_error(response, 'Error retrieving WL/BL Data')
        )




  #Inline Adjust WL/BL Button
  $('.dispute-inline-buttons.adjust-wlbl-button').click ->
    dropdown = $(this).next('.dropdown-menu')
    comment_wrapper = $(dropdown).find('.comment-wrapper')
    submit_button = $(dropdown).find('.dropdown-submit-button')
    list_toggle = $(dropdown ).find('.wl-bl-list-inline')
    initial_val = ''

    $(list_toggle).each ->
      initial_val = $(this).prop("checked")

      $(this).click ->
        if $(this).prop("checked") != initial_val
          $(comment_wrapper).show()
          $(submit_button).attr("disabled", false)


  # Show / hide the different research tables in the expanded row
  $('.research-row-checkbox').click ->
    entry_row = $(this).parents('.research-table-row')[0]

    if $(this).hasClass('wbrs-checkbox')
      table = $(entry_row).find('.wbrs-details-table')[0]

    if $(this).hasClass('sbrs-checkbox')
      table = $(entry_row).find('.sbrs-details-table')[0]

    if $(this).hasClass('virus-total-checkbox')
      table = $(entry_row).find('.virustotal-details-table')[0]

    if $(this).hasClass('xbrs-checkbox')
      table = $(entry_row).find('.xbrs-details-table')

    if $(this).hasClass('crosslisted-checkbox')
      table = $(entry_row).find('.crosslisted-details-table')[0]

    if $(this).hasClass('reptool-checkbox')
      table = $(entry_row).find('.reptool-details-table')[0]

    if $(this).prop('checked')
      $(table).show()
    else
      $(table).hide()

  # Tables in the expanded rows

  $('.virustotal-table').DataTable({
    info: false,
    ordering: true,
    paging: false,
    searching: false
  })

  $('.sbrs-table').DataTable({
    info: false,
    ordering: true,
    paging: false,
    searching: false
  })

  $('.shared-xbrs-timeline-table').DataTable({
    columnDefs: [
      {
        orderData: [6],
        targets: [0]
      },
      {
        visible: false,
        targets: [6]
      }
    ]
    info: false,
    ordering: true,
    paging: false,
    searching: false,
  })

  $('.wbrs-table').DataTable({
    columnDefs: [{
      targets: [0],
      orderable: false
    }]
    info: false,
    order: [[1, 'asc']],
    paging: false,
    searching: false
  })

  $('.crosslisted-table').DataTable({
    columnDefs: [
      {
        orderData: [7],
        targets: [5],
      },
      {
        orderData: [8],
        targets: [6],
      },
      {
        visible: false,
        targets: [7, 8]
      }
    ]
    info: false,
    paging: false,
    searching: false
  })

  #  Rule escalations email
  $('.wbrs-rule-trigger').click ->
    rule_id = $(this).attr('data-id')
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/rulehit_resolution_mailer_templates/make_rulehit_mail/#{rule_id}"
#      data: {status: 'read'}
      success_reload: false
      success: (response) ->
        response = JSON.parse(response)

        $('#communication-tab-link').trigger 'click'
        $('#newEmailDialog').dialog 'open'

        reciever_input = $('#newEmailDialog').find('.receiver-email')
        cc_input = $('#newEmailDialog').find('.cc-email')
        subject_input = $('#newEmailDialog').find('.communication-subject')
        body_input = $('#newEmailDialog').find('.email-reply-body')

        $(reciever_input[0]).val(response.to)
        $(cc_input[0]).val(response.cc)
        $(subject_input[0]).val(response.subject)
        $(body_input[0]).text(response.body)
      error: (response) ->
        std_api_error(response, "Template could not be retrieved.", reload: false)

    )
    return

  $('.adhoc-email-trigger').click ->
    data = {
      rulehit_name: $(this).attr('data-name')
      url: $(this).attr('data-url')
    }
    std_msg_ajax(
      method: 'POST'
      url: "/escalations/api/v1/rulehit_resolution_mailer_templates/make_adhoc_rulehit_mail"
      data: data
      success_reload: false
      success: (response) ->
        response = JSON.parse(response)

        $('#newEmailDialog').dialog 'open'

        reciever_input = $('#newEmailDialog').find('.receiver-email')
        cc_input = $('#newEmailDialog').find('.cc-email')
        subject_input = $('#newEmailDialog').find('.communication-subject')
        body_input = $('#newEmailDialog').find('.email-reply-body')

        $(reciever_input[0]).val(response.to)
        $(cc_input[0]).val(response.cc)
        $(subject_input[0]).val(response.subject)
        $(body_input[0]).text(response.body)
      error: (response) ->
        std_api_error(response, "Template could not be retrieved.", reload: false)

    )
    return

  # Sync / refresh entry data. Initiate modal / animation
  $('#sync-data-button').click ->

    data = {
      'dispute_id': $(".case-id-tag").html()
    }

    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/sync_data'
      method: 'POST'
      headers: headers
      data: data
      dataType: 'json'
      success: (response) ->
        response = JSON.parse(response)
        if response.status == "success"
          window.location.reload()
      error: (response) ->
        popup_response_error(response, 'Error Syncing Data')
        window.location.reload()
    )


  window.researchfilter = (element) ->
    query = $(element).val();
    #    Rather than doing the javascript .each for this, let's use CSS
    $(".entry-data-content:not(:contains('#{query}'))").parents('.research-table-row').hide()
    $(".entry-data-content:contains('#{query}')").parents('.research-table-row').show()


  window.dispute_entry_recovery = (dispute_id) ->
    # Something got lost, ping the bridge and pull in entry content
    std_msg_ajax(
      method: 'POST'
      url: "/escalations/api/v1/escalations/webrep/disputes/recover_dispute"
      data: {
        id: dispute_id
      }
      success: (response) ->
        std_msg_success("Entry content recovered", response.messages, reload: true)
      error: (response) ->
        std_api_error(response, "Error recovering dispute entry content", reload: false)
    )

$(document).ready ->

  # XBRS history on webrep: fixes to ensure showing the correct table headers, removing conflicting inline styles
  $('.xbrs-details-table .dataTables_scrollHead').addClass('hidden')
  $('.xbrs-details-table .dataTables_scrollBody').find('thead tr, th, th div').removeAttr('style')
