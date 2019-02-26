$ ->
  # go back to the last tab after reload

  $('a[data-toggle="tab"]').on 'shown.bs.tab', (e) ->
    localStorage.setItem 'lastTab', $(this).attr('id')
    return

  $(document).on 'ready page:load', (e) ->
    lastTab = localStorage.getItem('lastTab')
    if lastTab
      $('#' + lastTab).tab('show');
    else
      $('#communication-tab-link').tab('show')
    return


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
    edit_button = $(this)
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
    entry_id = $(this).attr('data-entry-id')
    entry_row = $(this).parents('.research-table-row')[0]
    nested_row = $(entry_row).find('.nested-data-row')[0]
    $(nested_row).toggle()
    $(expand_button).toggleClass('shown')


#  Populating the toolbar Adjust RepTool Button
  $('#reptool_entries_button').click ->
    dropdown = $('#reptool_adjust_entries').parent()

    # Only allowing a single submission at a time for now.
    if ($('.dispute_check_box:checked').length == 1)
      show_content = $('#reptool_adjust_entries').find('.entry-dispute-name')
      show_rep_class = $('#reptool_adjust_entries').find('.entry-reptool-class')
      show_rep_exp = $('#reptool_adjust_entries').find('.entry-reptool-expiration')
      submit_button = $('#reptool_adjust_entries').find('.dropdown-submit-button')
      comment_input = $('#reptool_adjust_entries').find('.comment-input')
      entry_content = ''
      $('.dispute_check_box').each ->
        if $(this).prop('checked')
          entry_row = $(this).parents('.research-table-row')[0]
          entry_content = $(entry_row).find('.entry-data-content').text()

      data = {
      # Send entry content to reptool
        'entry' : entry_content
      }

      headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
      $.ajax(
        url: '/escalations/api/v1/escalations/webrep/disputes/reptool_get_info_for_form'
        method: 'GET'
        headers: headers
        data: data
        dataType: 'json'
        success: (response) ->
          response = JSON.parse(response)
          $(show_content[0]).text(entry_content)
          $(show_rep_class[0]).text(response.classification)
          $(show_rep_exp[0]).text(response.expiration)
          $('#blacklist-action-select').val(response.status)
          $('#blacklist-classifications-select').val(response.classification)
          $(comment_input[0]).val(response.comment)
          $(submit_button).attr('disabled', false)
#          window.location.reload()
        error: (response) ->
          popup_response_error(response, 'Error retrieving Reptool Data')
      )
#

    else
      std_msg_error('No rows selected', ['Please select a row'])
      $(dropdown).removeClass('open')
      return false


  $('#reptool_index_entries_button').click ->
    dropdown = $('#reptool_adjust_entries').parent()

    # Only allowing a single submission at a time for now.
    if ($('.dispute-entry-checkbox:checked').length == 1)
      show_content = $('#reptool_adjust_entries').find('.entry-dispute-name')
      show_rep_class = $('#reptool_adjust_entries').find('.entry-reptool-class')
      show_rep_exp = $('#reptool_adjust_entries').find('.entry-reptool-expiration')
      submit_button = $('#reptool_adjust_entries').find('.dropdown-submit-button')
      comment_input = $('#reptool_adjust_entries').find('.comment-input')
      entry_content = ''
      $('.dispute-entry-checkbox').each ->
        if $(this).prop('checked')
          entry_row = $(this).parents('.index-entry-row')[0]
          entry_content = $(entry_row).find('.entry-col-content').text()

      data = {
# Send entry content to reptool
        'entry' : entry_content
      }

      headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
      $.ajax(
        url: '/escalations/api/v1/escalations/webrep/disputes/reptool_get_info_for_form'
        method: 'GET'
        headers: headers
        data: data
        dataType: 'json'
        success: (response) ->
          response = JSON.parse(response)
          $(show_content[0]).text(entry_content)
          $(show_rep_class[0]).text(response.classification)
          $(show_rep_exp[0]).text(response.expiration)
          $('#blacklist-action-select').val(response.status)
          $('#blacklist-classifications-select').val(response.classification)
          $(comment_input[0]).val(response.comment)
          $(submit_button).attr('disabled', false)
#          window.location.reload()
        error: (response) ->
          popup_response_error(response, 'Error retrieving Reptool Data')
      )
#

    else if $('.dispute-entry-checkbox:checked').length == 0
      std_msg_error('No rows selected', ['Please select one row'])
      $(dropdown).removeClass('open')
      return false
    else
      std_msg_error('Error', ['Please select one row'])
      $(dropdown).removeClass('open')
      return false

  ## WL/BL Form manipulation
  $('.wl-bl-list-inline').click ->
    wlbl_entries = $('#wlbl_adjust_entries').find('.wlbl-dropdown-row')
    wlbl_submit = $('#wlbl_adjust_entries').find('.dropdown-submit-button')
    if wlbl_entries.length > 0 && $('.wl-bl-list-inline:checked').length > 0
      wlbl_submit.attr('disabled', false)
    else
      wlbl_submit.attr('disabled', true)



  ## Populating the toolbar Adjust WL/BL Button (works for index, research page, and research tab of show page)
  window.bulk_get_current_wlbl = (page) ->
    entries_checked = []
    checkbox = ''
    row = ''
    tbody = ''
    current_wbrs = ''

    # Define variables based on what page we're on
    if page == 'index'
      checkbox = '.dispute-entry-checkbox'
      row = '.index-entry-row'
      tbody = $('#wlbl_adjust_entries_index').find('table.dispute_tool_current').find('tbody')
      current_wbrs = '.entry-col-wbrs-score'
    else if page == 'show' || page == 'research'
      checkbox = '.dispute_check_box'
      row = '.research-table-row'
      tbody = $('#wlbl_adjust_entries').find('table.dispute_tool_current').find('tbody')
      current_wbrs = '.current-wbrs-score'

    ## Clear out any residual data
    # Empty table
    $(tbody).empty()

    # Clear the checkboxes
    wl_weak = $('#wlbl_adjust_entries').find('.wl-weak-checkbox')
    wl_med = $('#wlbl_adjust_entries').find('.wl-med-checkbox')
    wl_heavy = $('#wlbl_adjust_entries').find('.wl-heavy-checkbox')
    bl_weak = $('#wlbl_adjust_entries').find('.bl-weak-checkbox')
    bl_med = $('#wlbl_adjust_entries').find('.bl-med-checkbox')
    bl_heavy = $('#wlbl_adjust_entries').find('.bl-heavy-checkbox')
    $(wl_weak[0]).prop('checked', false)
    $(wl_med[0]).prop('checked', false)
    $(wl_heavy[0]).prop('checked', false)
    $(bl_weak[0]).prop('checked', false)
    $(bl_med[0]).prop('checked', false)
    $(bl_heavy[0]).prop('checked', false)

    # Empty comment box
    comment_box = $('#wlbl_adjust_entries').find('.adjust-wlbl-input')
    $(comment_box).val('')

    ## Get data to populate table
    # Get all the checked entries
    $(checkbox).each ->
      if this.checked == true
        entries_checked.push(this)

    # Pull the entry content out
    if (entries_checked.length > 0)
      data = {'entries': []}
      wbrs = ''
      $(entries_checked).each ->
        # Slightly different structure to get the actual entry content
        if row == '.research-table-row'
          entry_row = $(this).parents('.research-table-row')[0]
          entry_content = $(entry_row).find('.entry-data-content').text()
          wbrs = $(entry_row).find(current_wbrs).text()
          console.log wbrs[0]
          data['entries'].push(entry_content)

        else if row == '.index-entry-row'
          entry_row = $(this).parents('.index-entry-row')[0]
          entry_content = $(entry_row).find('.entry-col-content').text()
          data['entries'].push("\n" + entry_content + "\n")
          wbrs = $(entry_row).find(current_wbrs).text()
          console.log wbrs[0]

      std_msg_ajax(
        url: '/escalations/api/v1/escalations/webrep/disputes/bulk_rule_ui_wlbl_get_info_for_form'
        method: 'POST'
        data: data
        success: (response) ->
          $(tbody).empty()
          response = JSON.parse(response)
          console.log response
          for entry in response
            ip_uri = entry['ip_uri']
            list_types = entry['list_types']
            wbrs_score = entry['wbrs_score']
            comment = entry['notes']
            if list_types
              list_types = entry['list_types']
            else
              list_types = ''
              wbrs_score = wbrs
            if wbrs_score == null
              wbrs_score = '<span class="missing-data">No score.</span>'
            if comment == null
              comment = ''

            $(tbody).append('<tr class="wlbl-dropdown-row">' + '<td class="wlbl-entry-content">' + ip_uri + '</td><td class="wlbl-entry-wlbl">' + list_types + '</td>' + '<td class="wlbl-current-entry-wbrs text-center">' + wbrs_score + '</td>')

        error: (response) ->
          std_msg_error( 'Error retrieving WL/BL Data', response)
      )
    else
      std_msg_error('No rows selected', ['Please select at least one entry row.'])
      $(dropdown).removeClass('open')
      return false


  ## Bulk submission of WL/BL changes (works on index, research page, and research tab of show page)
  window.bulk_adjust_wlbl = (page) ->
    data = {}
    ip_uris = []
    list_types = []
    list_types = $('.wl-bl-list-inline:checkbox:checked').map(() -> this.value).toArray()
    wlbl_comment = ''
    dropdown = ''

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

  $('.xbrs-short-scrollable').DataTable({
    scrollX: '90%',
    paging: false,
    searching: false,
    ordering: false,
    info: false
  })

  $('.xbrs-long-scrollable').DataTable({
    scrollY: 200,
    scrollX: '70%',
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

#    When data is finish loading
#    $('#loading-div').hide()
#    $('#api-msg').show()
#    $('#loader-modal.hidden).removeClass('hidden')
#    Display success message in modal

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

  $('.esc-tooltipped').tooltipster theme: [
    'tooltipster-borderless'
    'tooltipster-borderless-customized'
  ]

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
