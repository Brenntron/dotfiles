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
    else
      $('#research-page-toolbar').show()

  $(document).on 'ready page:load', (e) ->
    hide_toolbar()
    lastTab = localStorage.getItem('lastTab')
    if lastTab
      $('#' + lastTab).tab('show')
    else
      $('#communication-tab-link').tab('show')
    return

  $(document).on 'change', '#select-all-bulk', (e) ->
    # handles selection of all checkboxes in quicklookup table
    e_val = e.currentTarget.checked
    select_cols = $('.col-select-all input')
    for col in select_cols
      $(col).prop('checked', e_val)

  $(document).on 'change', '.col-select-all input', (e) ->
    # handles selection of sindlge checkboxes in quicklookup table
    select_cols = $('.col-select-all input')
    select_vals = []
    for col in select_cols
      select_vals.push( $(col).prop('checked') )
    bulk_value = select_vals.every( (col) -> return col)
    $('#select-all-bulk').prop('checked', bulk_value)

  $(document).on 'change', '.adjust_reptool_checkbox, .status_bl', () ->
    submit_btn = $('#reptool_entries_bl_dropdown .dropdown-submit-button')
    class_bl = $('.status_bl:checked').val().replace('reptool-', '')
    if $('.adjust_reptool_checkbox:checked').length || class_bl == 'drop'
      submit_btn.prop('disabled', false)
    else
      submit_btn.prop('disabled', true)

  $(document).on 'change', '.adjust_wlbl_checkbox', () ->
    submit_btn = $('#wlbl_entries_dropdown .dropdown-submit-button')
    if $('.adjust_wlbl_checkbox:checked').length
      submit_btn.prop('disabled', false)
    else
      submit_btn.prop('disabled', true)

  window.open_adjust_reptool = () ->
    dropdown = $('#reptool_entries_bl_dropdown')
    list = $(dropdown).find('ul')
    type = 'reptool'
    reptool_options = [ "attackers", "bogon", "bots", "cnc", "cryptomining",
              "dga", "exploit kit", "malware", "open_proxy", "open_relay",
              "phishing", "response", "spam", "suspicious", "tor_exit_node"]
    if !$(list).has('label').length
      build_checkbox_list(reptool_options, list, type)

  window.open_wlbl = () ->
    dropdown = $('#wlbl_entries_dropdown')
    list = $(dropdown).find('ul')
    type = 'wlbl'
    wlbl_options = [ "WL - Weak", "WL - Medium", "WL - Heavy",
                     "BL - Weak", "BL - Medium", "BL - Heavy"]
    if !$(list).has('label').length
      build_checkbox_list(wlbl_options, list, type)

  window.build_checkbox_list = (arr, list, type) ->
    # the checkbox list for the dropdown is built here when the dropdown is first opened
    # because I don't want to type the same html element over and over
    for opt in arr
      checkbox =
        '<li> <label>' +
          '<input name="' + opt + '" value="' + opt + '"type ="checkbox" class="adjust_' + type + '_checkbox"/>'+ opt +
        '</label> </li>'
      $(list).append(checkbox)

  window.set_action_wlbl_col = () ->
    dropdown = $('#wlbl_entries_dropdown')
    selected_rows = $('.col-select-all input:checked')
    list_action = $('.wlbl-radio-add:checked').val()

    if list_action == 'add'
      list_action = 'Add to: '
    else
      list_action = 'Remove from: '

    checked_bl = $('.adjust_wlbl_checkbox:checked')
    check_list = []
    for item in checked_bl
      check_name = "<span class='col-tag'>" + $(item).val() + "</span> "
      check_list.push(check_name)

    if check_list.length == 2
      check_list = check_list.join(' and ')
    else
      check_list = check_list.join(', ').replace(/, ([^,]*)$/, ', and $1')

    col_dialog = "<p class='wlbl-action-col'>" + list_action + check_list + "<p>"

    selected_rows.each ()->
      row = $(this).closest('tr')
      data = row.find('.col-bulk-dispute').text()
      action_col = row.find('.col-actions')
      existing_p = action_col.find('.wlbl-action-col')

      if !isEmpty(data)
        $(existing_p).remove()
        $(action_col).append(col_dialog)

  window.set_action_col = () ->
    dropdown = $('#reptool_entries_bl_dropdown')
    selected_rows = $('.col-select-all input:checked')

    checked_bl = $(dropdown).find('.adjust_reptool_checkbox:checked')
    check_list = []
    class_bl = $('.status_bl:checked').val().replace('reptool-', '')

    for item in checked_bl
      check_name = "<span class='col-tag'>" + $(item).val() + "</span> "
      check_list.push(check_name)

    if check_list.length == 2
      check_list = check_list.join(' and ')
    else
      check_list = check_list.join(', ').replace(/, ([^,]*)$/, ', and $1')

    switch (class_bl)
      when 'maintain'
        status_string = 'Add classifications: '
      when 'override'
        status_string = 'Remove classifications: '
      when 'drop'
        status_string = 'Drop all classifications (set entry to EXPIRED)'
        check_list = ''

    col_dialog = "<p class='reptool-action-col'>" + status_string + check_list + "<p>"

    selected_rows.each ()->
      row = $(this).closest('tr')
      data = row.find('.col-bulk-dispute').text()
      action_col = row.find('.col-actions')
      existing_p = action_col.find('.reptool-action-col')
      if !isEmpty(data)
        $( existing_p).remove()
        $(action_col).append(col_dialog)

  window.isEmpty = (item) ->
    # function to check whether or not objects and strings are empty, more variable types can be added as needed
    type = typeof item
    switch(type)
      when 'object'
        return !Object.keys(item).length
      when 'string'
        return /^\s*$/.test(item)

  window.buildRow = ( text_list, parent_row) ->
    # build and append new rows to the HTML in quick lookup
    tbody = document.querySelector('.research-table tbody')
    disputes = []
    disputes_data = []
    existing_rows = $(tbody).find('tr')
    parent_data = $(parent_row).find('.col-bulk-dispute').attr('data')
    parent_index = parent_row.rowIndex
    prev_row = existing_rows.eq(parent_index - 2)[0].innerText

    $(existing_rows).each ->
      data = $(this).find('.col-bulk-dispute').attr('data')
      if !isEmpty(data)
        disputes_data.push(data)
        disputes.push(this)

    if !isEmpty(parent_data) && !text_list.includes(parent_data)
      index = disputes.indexOf(parent_data)
      disputes.splice(index, 1);
      parent_index = parent_index - 1

    text_list = text_list.filter( (text)-> return !disputes_data.includes(text) )
    text_list.push(' ')
    enter_check = isEmpty(prev_row) && text_list.length == 1 && parent_index > 1 || isEmpty(parent_data)

    if disputes.length
      if enter_check
        parent_index = parent_index - 1
      for i in [0...text_list.length]
        disputes.splice parent_index + i, 0, text_list[i]
    else
      for i in [0...text_list.length]
        disputes.push(text_list[i])

    # reset the innerHTML to nothing
    tbody.innerHTML = ''
    for i in [0...disputes.length]
      # if the dispute is not an HTML object, set the HTML of the new row to the below
      if typeof disputes[i] != 'object'
        tbody.innerHTML +=
          '<tr>' +
            '<td class="col-select-all">' +
            '<span class="checkbox-wrapper">' +
            '<input type="checkbox" checked>' +
            '</span>' +
            '</td>'+
            '<td class="col-bulk-dispute" contenteditable="true" data=' + disputes[i] + '><p>' + disputes[i] + '</p></td>'+
            '<td class="col-wbrs"></td>'+
            '<td class="col-wbrs-rule-hits"></td>'+
            '<td class="col-wbrs-rules"></td>'+
            '<td class="col-category"></td>'+
            '<td class="col-wlbl"></td>'+
            '<td class="col-reptool-class"></td>'+
            '<td class="col-actions" data=""></td>' +
            '</tr>'
      else
        # if the dispute is an HTML object, set it as OuterHTML to avoid formatting issues
        tbody.innerHTML += disputes[i].outerHTML

      # Once the table has been rebuilt, find the empty row and focus on it
      col_dispute = $(tbody).find('tr .col-bulk-dispute')
      col_dispute.each ->
        if isEmpty( $(this).attr('data') )
          this.focus()

      setTimeout () ->
        $("br").remove()
      , 20

  window.bindControls = () ->
    # unbind and rebind focusout to prevent the rebuilding of the table from being stuck in a loop
    $(document).unbind('focusout')
    setTimeout () ->
      $( document ).on 'focusout', '.col-bulk-dispute', (e) -> set_row_text(e, this)
    , 250

  set_row_text = (e, el) ->
    { which: key, type, shiftKey } = e

    text = el.innerText.trim()
    text_list = text.replace( /\n|\s/g, ", " ).split(", ")
    row = el.closest('tr')
    tbody = row.closest('tbody')

    text_list = text_list.filter( (item, index) ->
      if item != ''
        return text_list.indexOf item == index
    )
    switch( key )
      when 13
        if !shiftKey && text_list.length
          bindControls()
          buildRow(text_list, row)
      when 0
        if text_list.length > 1
          buildRow(text_list, row)
        else
          $(row).data(text)
      when 8
        if isEmpty(text) && $(tbody).children().length > 1
          $(row).remove()

  $( document ).on 'keydown focusout', '.col-bulk-dispute', (e) ->
    set_row_text(e, this)
    e.stopPropagation()

  $(document).ajaxStop ()->
    # Once all ajax calls have been completed, hide the  on page loader svg
    $('.ajax-message-div').hide()

  $(document).on 'click', '#get-rep-data', (e) ->
    e.preventDefault()
    search_items = []
    rows = $('.research-table tbody tr')
    headers = { 'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val() }

    $('.col-bulk-dispute').each( ( ) ->
      text = $(this).text()
      if text != ''
        search_items.push(text)
    )

    for i in [0...search_items.length]
      item = search_items[i]
      row = rows[i]

      if !isEmpty(item)
        $('.ajax-message-div').css('display':'flex')
        # for each search item, call a promise to get the data. If success, the first then runs, setting the data in the rows.
        # if it fails, the secon runs, catching the error
        new get_reptool(item, headers)
          .then ( set_reptool.bind( null, item, row) )
          .then null, (err) -> console.log err
        new get_wlbl(item, headers)
          .then( set_wlbl.bind( null, item, row) )
          .then null, (err) -> console.log err
        new get_cat(item, headers)
          .then ( set_cat.bind( null, item, row) )
          .then null, (err) -> console.log err
        new get_wrbs(item, headers)
          .then( set_wrbs.bind( null, item, row) )
          .then null, (err) -> console.log err

  window.set_reptool = ( item, row, data) ->
    { classification } = JSON.parse(data)[0]
    col_reptool = $(row).children('.col-reptool-class')

    if classification != 'No active classifications'
      new_reptool = classification.toString()
      col_reptool.text( new_reptool )
    else
      col_reptool.text( 'Not on RepTool' )
      col_reptool.addClass('missing-data')

  window.set_wlbl = ( item, row, data) ->
    { data } = JSON.parse(data)
    col_wlbl = $(row).children('.col-wlbl')

    if data.length > 1
      data = data.join(', ')
    col_wlbl.text( data )

  window.set_cat = ( item, row, data) ->
    { data } = JSON.parse(data)
    cat_col = $(row).children('.col-category')

    if !isEmpty(data)
      categories = ''
      for key, value of data
        { descr } = value
        categories += descr + ', '
      categories = categories.substring(0, categories.length - 2)
      cat_col.text( categories )
    else
      cat_col.text('No data')
      cat_col.addClass('missing-data')

  window.set_wrbs = ( item, row, data) ->
    { score, rulehits } = data.json.data
    col_wbrs = $(row).children('.col-wbrs')
    col_wbrs_rule = $(row).children('.col-wbrs-rules')
    col_wbrs_hits = $(row).children('.col-wbrs-rule-hits')

    col_wbrs_rule.text( rulehits.join(', ') )
    col_wbrs_hits.text( rulehits.length )
    if score != 'noscore'
      col_wbrs.text( score )
    else
      col_wbrs.text( '0.0' )


  window.get_reptool = (item, headers) ->
    data = {'ip_uris':[item]}
    $.ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/bulk_reptool_get_info_for_form'
      method: 'POST'
      data: data
      headers: headers
      success: (response) ->
        return response
      error: (response) ->
        return response
    )

  window.get_wlbl = (item, headers) ->
    data = {'entry': item}
    $.ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/rule_ui_wlbl_get_info_for_form'
      method: 'GET'
      headers: headers
      data: data
      dataType: 'json'
      success: (response) ->
        return response
      error: (response) ->
        return response
    )
  window.get_wrbs = (item, headers) ->
    data = {'uri': item}
    $.ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/wbrs_info'
      method: 'GET'
      headers: headers
      data: data
      dataType: 'json'
      success: (response) ->
        return response
      error: (response) ->
        return response
    )

  window.get_cat = (item, headers) ->
    data = {'uri': item}
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaints/uri_cat_info'
      method: 'GET'
      headers: headers
      data: data
      dataType: 'json'
      success: (response) ->
        return response
      error: (response) ->
        return response
    )

->

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
          data['entries'].push(entry_content)

        else if row == '.index-entry-row'
          entry_row = $(this).parents('.index-entry-row')[0]
          entry_content = $(entry_row).find('.entry-col-content').text()
          data['entries'].push("\n" + entry_content + "\n")
          wbrs = $(entry_row).find(current_wbrs).text()

      std_msg_ajax(
        url: '/escalations/api/v1/escalations/webrep/disputes/bulk_rule_ui_wlbl_get_info_for_form'
        method: 'POST'
        data: data
        success: (response) ->
          $(tbody).empty()
          response = JSON.parse(response)
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
