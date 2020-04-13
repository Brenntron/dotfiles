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


# Inline Edit Status
  $('.radio-label').click ->
    radio_button = $(this).prev('input[type="radio"]')
    $(radio_button[0]).trigger('click')
    dropdown_wrapper = $(this).parents('.inline-dropdown-menu')
    active_status = $(dropdown_wrapper[0]).prev('.inline-select-dropdown')
    if $(radio_button[0]).hasClass('entry-status-radio')
      selected_status = $(radio_button[0]).attr('id')
      $(active_status[0]).text(selected_status)

    li = $(this).parent('.status-radio-wrapper')
    parent = li[0]
    $('.status-radio-wrapper').each ->
      if $(this).hasClass('selected')
        $(this).removeClass('selected')
    $(parent).addClass('selected')

    if radio_button.hasClass('resolution-drodown-menu') or radio_button.hasClass('entry-resolution-radio')
      submenu = $(this).siblings('.dropdown-menu')
      $(submenu[0]).show()
      return false
    else
      $('.ticket-resolution-submenu').hide()

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

  ##  Populating the toolbar Adjust RepTool BL dropdown
  window.bulk_get_current_reptool = (page) ->

# Define the variables based on the page
    if page == "show" || page == "research"
      checkbox = $('.dispute_check_box:checked')
    else if page == "index"
      checkbox = $('.dispute-entry-checkbox:checked')

    ## Clear out any residual data
    # Empty table
    tbody = $('#reptool_adjust_entries').find('table.dispute_tool_current').find('tbody')
    tbody.empty()
    # Empty the comment box
    comment_box = $('#reptool_adjust_entries').find('.comment-input')
    comment_box.val('')

    ## Get data to populate table
    # Get all the checked entry urls
    if ($(checkbox).length > 0)
      ip_uris = []
      $(checkbox).each ->
        if page == "show" || page == "research"
          entry_row = $(this).parents('.research-table-row')[0]
          entry_content = $(entry_row).find('.entry-data-content').text().trim()
        else if page == "index"
          entry_row = $(this).parents('.index-entry-row')[0]
          entry_content = $(entry_row).find('.entry-col-content').text().trim()
        # Send entry content to reptool
        ip_uris.push(entry_content)

      std_msg_ajax(
        url: '/escalations/api/v1/escalations/webrep/disputes/bulk_reptool_get_info_for_form'
        method: 'POST'
        data: { ip_uris: ip_uris }
        success: (response) ->
          response = JSON.parse(response)

          for entry in response
            if entry['status'] == "ACTIVE"
              rep_class_full = entry['classification'] + ' - ' + entry['expiration']
              rep_class = entry['classification']
            else
              rep_class_full = '<span class="missing-data">No active classifications</span>'
              rep_class = ''

            tbody.append('<tr class="reptool-entry-row"><td class="reptool-entry-name">' + entry['entry'] + '</td><td class="reptool-entry-class" data-classification="' + rep_class + '">' + rep_class_full + '</td><td class="reptool-entry-comment">' + entry['comment'] + '</td></tr>')
        error: (response) ->
          std_api_error(response, "Error retrieving Reptool Data", reload: false)
      )
    else
      std_msg_error('Error', ['Please select one row'])
      $(dropdown).removeClass('open')
      return false

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
    entry_id = $(this).val()
    entry_row = $(this).parents('.research-table-row')[0]
    if $(this).hasClass('wbrs-checkbox')
      wbrs_table = $(entry_row).find('.wbrs-details-table')[0]
      if $(this).prop('checked')
        $(wbrs_table).show()
      else
        $(wbrs_table).hide()

    if $(this).hasClass('sbrs-checkbox')
      sbrs_table = $(entry_row).find('.sbrs-details-table')[0]
      if $(this).prop('checked')
        $(sbrs_table).show()
      else
        $(sbrs_table).hide()

    if $(this).hasClass('virus-total-checkbox')
      vt_table = $(entry_row).find('.virustotal-details-table')[0]
      if $(this).prop('checked')
        $(vt_table).show()
      else
        $(vt_table).hide()

    if $(this).hasClass('xbrs-checkbox')
      xbrs_table = $(entry_row).find('.xbrs-details-table')[0]
      if $(this).prop('checked')
        $(xbrs_table).show()
      else
        $(xbrs_table).hide()

    if $(this).hasClass('crosslisted-checkbox')
      cl_table = $(entry_row).find('.crosslisted-details-table')[0]
      if $(this).prop('checked')
        $(cl_table).show()
      else
        $(cl_table).hide()

    if $(this).hasClass('reptool-checkbox')
      rt_table = $(entry_row).find('.reptool-details-table')[0]
      if $(this).prop('checked')
        $(rt_table).show()
      else
        $(rt_table).hide()





  # Scrollable tables in the expanded rows
  $('.table-scrollable').DataTable({
    scrollY: 200,
#    scrollCollapse: true,
    paging: false,
    searching: false,
    ordering: false,
    info: false
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
#    If cannot connect to resync data
#    Show error message modal
#    Else
    $('#loader-modal').modal({
      backdrop: 'static',
      keyboard: false
    })

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
    $('.entry-data-content:not(:contains(' + query + '))').parents('.research-table-row').hide()
    $('.entry-data-content:contains(' + query + ')').parents('.research-table-row').show()


$(document).ready ->

  ### Using 'tooltipped' class instead of 'tooltip' so that it doesn't interfere with Bootstrap ###
#    Edit Ticket (Show page). Edit Ticket Status
  $('.ticket-status-radio-label').click ->
    radio_button = $(this).prev('.ticket-status-radio')
    $(radio_button[0]).trigger('click')
    if $(radio_button).attr('id') == 'RESOLVED_CLOSED'
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

  $('.ticket-status-radio').click ->
    all_stat_radios = $('#show-edit-ticket-status-dropdown').find('.status-radio-wrapper')
    if $(this).is(':checked')
      wrapper = $(this).parent()
      $(all_stat_radios).removeClass('selected')
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


  # XBRS history on webrep: fixes to ensure showing the correct table headers, removing conflicting inline styles
  $('.xbrs-details-table .dataTables_scrollHead').addClass('hidden')
  $('.xbrs-details-table .dataTables_scrollBody').find('thead tr, th, th div').removeAttr('style')
