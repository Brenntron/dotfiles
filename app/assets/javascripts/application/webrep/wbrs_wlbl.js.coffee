################################################################################
# FUNCTIONS FOR POPULATING, SUBMITTING, ETC. WBRS WL/BL INFORMATION
################################################################################



#### POPULATING CURRENT WL/BL LISTS ####

## Populating the INLINE Adjust WL/BL dropdown for
## research page and research tab (individual submission form)
window.get_current_wlbl = (button) ->
  # Get entry content
  research_row = $(button).parents('.research-table-row')[0]
  entry_wrapper = $(research_row).find('.entry-data-content')[0]
  entry_content = $(entry_wrapper).text().trim()
  wbrs = $($(research_row).find('.entry-data-wbrs-score')[0]).text()
  tc_cell = $($(research_row).find('.wlbl-threat-cat-inline')[0])

  if $('#dispute_id').length > 0
    case_id = $('#dispute_id').text()
    comment_text = '\n \n------------------------------- \nINDIVIDUAL SUBMISSION: \n #' + case_id + ' - ' + entry_content
  else
    comment_text = '\n \n------------------------------- \nRESEARCH SUBMISSION: \n ' + entry_content

  # Define fields that need to be filled out in the dropdown
  dropdown = $(button).next('.dropdown-menu')[0]
  preview_button = $(dropdown).find('.preview-wbrs-button')
  preview_score = $(dropdown).find('.wlbl-projected-entry-wbrs')

  # Reset the preview button and any leftover preview score
  $(preview_button).attr('disabled', true)
  $(preview_button).attr('data-remove', '')
  $(preview_button).attr('data-add', '')
  $(preview_score).text('')
  wlbl_list = $(dropdown).find('.wlbl-entry-wlbl')
  wbrs_score = $(dropdown).find('.wlbl-current-entry-wbrs')
  submit_button = $(dropdown).find('.dropdown-submit-button')
  comment = $(dropdown).find('.adjust-wlbl-input')
  wl_weak = $(dropdown).find('.wl-weak-checkbox')
  wl_med = $(dropdown).find('.wl-med-checkbox')
  wl_heavy = $(dropdown).find('.wl-heavy-checkbox')
  bl_weak = $(dropdown).find('.bl-weak-checkbox')
  bl_med = $(dropdown).find('.bl-med-checkbox')
  bl_heavy = $(dropdown).find('.bl-heavy-checkbox')

  # Clearing data to start in case user has page open for a while
  # and data needs to be regrabbed
  $(wlbl_list[0]).empty()
  $(wbrs_score[0]).empty()
  $(wl_weak[0]).prop('checked', false)
  $(wl_med[0]).prop('checked', false)
  $(wl_heavy[0]).prop('checked', false)
  $(bl_weak[0]).prop('checked', false)
  $(bl_med[0]).prop('checked', false)
  $(bl_heavy[0]).prop('checked', false)
  wl_weak_status = 'false'
  wl_med_status = 'false'
  wl_heavy_status = 'false'
  bl_weak_status = 'false'
  bl_med_status = 'false'
  bl_heavy_status = 'false'

  # Initializing 'current' status of lists to be filled in when data is fetched
  initial_wl_weak_status = ''
  initial_wl_med_status = ''
  initial_wl_heavy_status = ''
  initial_bl_weak_status = ''
  initial_bl_med_status = ''
  initial_bl_heavy_status = ''

  # Send entry content to wbrs
  data = {
    'entry': entry_content
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/rule_ui_wlbl_get_info_for_form'
    method: 'GET'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      # values will be in the format of BL-med, BL-weak, BL-heavy   (same with WL)
      response = JSON.parse(response)
      if response.data != ""
        $(response.data).each ->
          if String(this) == 'WL-weak'
            $(wl_weak[0]).prop('checked', true)
            wl_weak_status = 'true'
            initial_wl_weak_status = wl_weak_status
          if String(this) == 'WL-med'
            $(wl_med[0]).prop('checked', true)
            wl_med_status = 'true'
            initial_wl_med_status = wl_med_status
          if String(this) == 'WL-heavy'
            $(wl_heavy[0]).prop('checked', true)
            wl_heavy_status = 'true'
            initial_wl_heavy_status = wl_heavy_status
          if String(this) == 'BL-weak'
            $(bl_weak[0]).prop('checked', true)
            bl_weak_status = 'true'
            initial_bl_weak_stats = bl_weak_status
          if String(this) == 'BL-med'
            $(bl_med[0]).prop('checked', true)
            bl_med_status = 'true'
            initial_bl_med_status = bl_med_status
          if String(this) == 'BL-heavy'
            $(bl_heavy[0]).prop('checked', true)
            bl_heavy_status = 'true'
            initial_bl_heavy_status = bl_heavy_status

          # inline dropdowns only: if BL exists, show the tc row and toggle the existing tc's
          switch this.toString()
            when 'BL-weak', 'BL-med', 'BL-heavy'
              $(dropdown).find('.threat-cat-row').removeClass('hidden')

              tc_promise = new Promise (resolve, reject) ->   # get and set the threat categories with a promise
                tc_json = get_threat_categories(entry_content)
                if tc_json then resolve tc_json  # resolve goes to .then() below
              tc_promise.then (result) ->
                {threat_categories} = JSON.parse(result)
                if threat_categories.length == 0
                  tc_str = '<span class="threat-cat-no-data">No Category</span>'
                else tc_str = threat_categories.join(', ')

                $(tc_cell).html(tc_str)  # 1) place the tc's in the html after promise resolves
                $(dropdown).find('.threat-cat-cell').each ->  # 2) pre-toggle the tc cb's in the threat-cat-row
                  text = $(this).text().trim()
                  input = $(this).find('input:checkbox')
                  $(threat_categories).each (i, value) ->
                    if value == text then input.prop('checked', true)

        $(wbrs_score).text(wbrs)
        $(wlbl_list[0]).text(response.data.join(', '))
        $('.wlbl-entry-wlbl').text(response.data.join(', '))
        $(submit_button[0]).attr('disabled', true)
      else
        $(wbrs_score).text(wbrs)
        $(wlbl_list[0]).text('Not on a list')
        $(submit_button[0]).attr('disabled', true)
    $(comment).text(comment_text)
    error: (response) ->
      popup_response_error(response, 'Error retrieving WL/BL Data')
  )


## Populating the toolbar Adjust WL/BL dropdown BULK
## This works for index, research page, and research tab of show page
window.bulk_get_current_wlbl = (page) ->
  entries_checked = []
  checkbox = ''
  row = ''
  tbody = ''
  current_wbrs = ''
  comment_box = ''
  dropdown_wrapper = ''

  # Define variables based on what page we're on
  if page == 'index'
    dropdown_wrapper = $('#wlbl_adjust_entries_index')
    checkbox = '.dispute-entry-checkbox'
    row = '.index-entry-row'
    current_wbrs = '.entry-col-wbrs-score'
    case_id = []

  else if page == 'show'
    dropdown_wrapper = $('#wlbl_adjust_entries')
    checkbox = '.dispute_check_box'
    row = '.research-table-row'
    current_wbrs = '.current-wbrs-score'
    case_id = $('#dispute_id').text()

  else if page == 'research'
    dropdown_wrapper = $('#wlbl_adjust_entries')
    checkbox = '.dispute_check_box'
    row = '.research-table-row'
    current_wbrs = '.current-wbrs-score'
    case_id = ''

  tbody = $(dropdown_wrapper).find('table.dispute_tool_current').find('tbody')
  comment_box = $(dropdown_wrapper).find('.adjust-wlbl-input')

  ## Clear out any residual data
  # Empty table
  $(tbody).empty()
  # Empty comment box
  $(comment_box).text('')

  # Clear the checkboxes
  wl_weak = $(dropdown_wrapper).find('.wl-weak-checkbox')
  wl_med = $(dropdown_wrapper).find('.wl-med-checkbox')
  wl_heavy = $(dropdown_wrapper).find('.wl-heavy-checkbox')
  bl_weak = $(dropdown_wrapper).find('.bl-weak-checkbox')
  bl_med = $(dropdown_wrapper).find('.bl-med-checkbox')
  bl_heavy = $(dropdown_wrapper).find('.bl-heavy-checkbox')
  $(wl_weak[0]).prop('checked', false)
  $(wl_med[0]).prop('checked', false)
  $(wl_heavy[0]).prop('checked', false)
  $(bl_weak[0]).prop('checked', false)
  $(bl_med[0]).prop('checked', false)
  $(bl_heavy[0]).prop('checked', false)

  ## Get data to populate table
  # Get all the checked entries
  $(checkbox).each ->
    if this.checked == true
      entries_checked.push(this)

  # Pull the entry content out
  if (entries_checked.length > 0)
    entries = []
    wbrs = ''
    comment_trail = ''
    comment_array = []
    $(entries_checked).each ->
      # Slightly different structure to get the actual entry content
      if row == '.research-table-row'
        entry_row = $(this).parents(row)[0]
        entry_content = $(entry_row).find('.entry-data-content').text().trim()
        wbrs = $(entry_row).find(current_wbrs).text()
      else if row == '.index-entry-row'
        entry_row = $(this).parents(row)[0]
        entry_content = $(entry_row).find('.entry-col-content').text().trim()
        entry_case_id = $(entry_row).attr('data-case-id')
        wbrs = $(entry_row).find(current_wbrs).text()
        comment_array.push('#' + entry_case_id + ' - ' + entry_content)

      entries.push(entry_content)
    data = {'entries': entries}

    if page == "show"
      comment_trail = '\n \n------------------------------- \nBULK SUBMISSION: \n #' + case_id + ' - ' + entries.join(', ')
    else if page == "research"
      comment_trail = '\n \n------------------------------- \nRESEARCH BULK SUBMISSION: \n' + entries.join('\n')
    else if page == "index"
      comment_trail = '\n \n------------------------------- \nBULK SUBMISSION: \n' + comment_array.join('\n')

    # add some loading text while the tbody gets built
    $(tbody).empty().html('<tr class="loading-tbody"><td>Loading... ' +
      '<div class="glyphicon glyphicon-refresh mini-loader"></div></td></tr>')

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/bulk_rule_ui_wlbl_get_info_for_form'
      method: 'POST'
      data: data
      success: (response) ->
        response = JSON.parse(response)
        for entry in response
          tc_promise = new Promise (resolve, reject) ->   # wait until that tc is resolved to write out the table row
            tc_json = get_threat_categories(entry.ip_uri)
            if tc_json then resolve tc_json  # resolve goes to .then() below

          .then(
            build_tc_row.bind(null, entry, tbody)

          )
          .then( add_order_ids() )
          .then( order_rows() )

          .then null, (err) ->
            std_msg_error( 'Error retrieving WL/BL Data', response)  # handle this error more silently if needed

          comment_box.text(comment_trail)
      error: (response) ->
        std_msg_error( 'Error retrieving WL/BL Data', response)
    )
  else
    std_msg_error('No rows selected', ['Please select at least one entry row.'])
    return false


  # sort the rows in the mini-table in the dropdown after table is built
  add_order_ids = () ->
    row_id = 0
    setTimeout ( ->   # convert timeout to a promise
      $('#disputes-index').find('.dispute-entry-checkbox:checked').each ->
        ip_uri = $(this).closest('tr').find('.entry-col-content').text().trim()  # get the url from the left row
        $(this).closest('tr').attr('data-order-id', row_id)  # add row-id to the checked row

        $('#wlbl_adjust_entries_index').find('.wlbl-entry-content').each ->
          if $(this).text().includes(ip_uri)
            $(this).closest('tr').attr('data-order-id', row_id)
        row_id++
    ), 2000

  order_rows = () ->
    setTimeout ( ->   # convert timeout to a promise
      tbody = $('#wlbl_adjust_entries_index tbody')
      rows = $(tbody).find('tr')
      rows.sort (a, b) ->
        x = $(a).attr('data-order-id')
        y = $(b).attr('data-order-id')
        x - y

      $.each rows, (i, row) ->
        tbody.append(row)
        return
    ), 3000


  # ensures the table row w/ tc gets built correctly (KH refactor)
  build_tc_row = (entry, tbody, result) ->
    { threat_categories } = JSON.parse(result)
    { ip_uri, list_types, wbrs_score, comment } = entry
    tc_str = threat_categories.join(', ')

    if list_types
      list_types = entry['list_types'].sort().reverse().join(', ')  # sort by weak, then med, then heavy
      if list_types.includes('BL-')  # show 'replace tc' radio if bl exists
        $('.replace-tc-radio').removeClass('hidden')
    else
      list_types = ''
      wbrs_score = wbrs
    if !wbrs_score
      wbrs_score = '<span class="missing-data text-left">No Score</span>'
    if !comment then comment = ''

    table_row =
      '<tr class="wlbl-dropdown-row">' +
        '<td class="wlbl-entry-content">' + ip_uri + '</td>' +
        '<td class="wlbl-entry-wlbl">' + list_types + '</td>' +
        '<td class="wlbl-current-entry-wbrs text-center">' + wbrs_score + '</td>' +
        '<td class="wlbl-threat-cat">' + tc_str + '</td>' +
      '</tr>'

    $(tbody).append(table_row)
    $(tbody).find('.loading-tbody').addClass('hidden')



#### SUBMISSION OF WL/BL CHANGES TO WBRS ####

## Individual submission of WL/BL changes - INLINE row dropdown form
## Research page and research tab of show page
window.submit_individual_wlbl =(button_tag) ->
  list_types = $('.wl-bl-list-inline:checkbox:checked').map(() ->
    this.value
  ).toArray()
  wlbl_form = button_tag.form;

  data = {
    'urls': [ wlbl_form.getElementsByClassName('dispute-entry-content')[0].value ]
    'trgt_list': list_types,
    'thrt_cat_ids': [ parseInt(wlbl_form.getElementsByClassName('wlbl_thrt_cat_id')[0].value) ]
    'note': wlbl_form.getElementsByClassName('note-input')[0].value
  }

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/uri_wlbl'
    method: 'POST'
    data: data
    error_prefix: 'Error adjusting WL/BL.'
    success_reload: true
  )


## Bulk submission of WL/BL changes - toolbar dropdown form
## This works on index, research page, and research tab of show page
window.submit_bulk_wlbl = (page) ->
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

    thrt_cat_ids = []
    thrt_cat_names = []
    thrt_cat_array = $(dropdown).find('.wlbl_thrt_cat_id')

    $(thrt_cat_array).each ->
      if $(this).prop('checked')  # if tc cb checked, add the value to this id array (val == id)
        thrt_cat_ids.push($(this).val())
        thrt_cat_names.push($(this).parent().text().trim())

    # TODO: need BACK-END ASSISTANCE for below, array is passed to back-end, something is broken
    console.log thrt_cat_ids + ' these ids are getting passed to back-end'
    data = {ip_uris: ip_uris, list_types: list_types, note: wlbl_comment, thrt_cat_ids: thrt_cat_ids}

    if thrt_cat_ids.length  # if tc's were involved, and adding/replacing, add these strings, removing is just for wl/bl
      tc_added_str = '<br><p>With the following Threat Category(s): ' + thrt_cat_names.join(', ') + '</p>'
      tc_replaced_str = '<br><p>With the following Threat Category(s) replaced: ' + thrt_cat_names.join(', ') + '</p>'
    else
      tc_added_str = ''
      tc_replaced_str = ''

    # add to list and replace threat cats use the same thing below
    if $('#wlbl-add').prop('checked') or $('#wlbl-replace').prop('checked')
      std_msg_ajax(
        url: '/escalations/api/v1/escalations/webrep/disputes/bulk_rule_ui_wlbl_add'
        method: 'POST'
        data: data
        success: (response) ->
          std_msg_success("The following entries have been added to " + list_types, [ip_uris, tc_added_str])
        error: (response) ->
          std_api_error(response, 'Error retrieving WL/BL Data')
      )
    else if $('#wlbl-remove').prop('checked')
      std_msg_ajax(
        url: '/escalations/api/v1/escalations/webrep/disputes/bulk_rule_ui_wlbl_remove'
        method: 'POST'
        data: data
        success: (response) ->
          std_msg_success("The following entries have been removed from " + list_types, ip_uris)
        error: (response) ->
          std_api_error(response, 'Error retrieving WL/BL Data')
      )



#### PREVIEWING WBRS SCORES ####
## Only available on individual / inline row dropdowns
## Research page and research tab of show page

# Prepping for previewing WBRS Score
window.prepare_for_wbrs_preview = (toggle) ->
# Get the current wl/bl settings
  dropdown = $(toggle).parents('.dispute-wlbl-adjust-wrapper')[0]
  current_lists = $($(dropdown).find('.wlbl-entry-wlbl')[0]).text()
  list = current_lists.split(',')
  # Get the settings of all the checkboxes
  checkboxes = $(dropdown).find('.wl-bl-list-inline')
  checked = $(dropdown).find('.wl-bl-list-inline:checked')
  preview_button = $(dropdown).find('.preview-wbrs-button')

  changed = []
  current_on = []
  current_off = []
  add = []
  remove = []

  if current_lists == "Not on a list"
    $(checked).each ->
      changed.push('changed')
  else
    $(checkboxes).each ->
      checkbox = this
      val = $(checkbox).val()
      $(list).each ->
        current = this.toString()
        if current == val
          current_on.push(checkbox)

  # Any checkbox that doesn't match the current lists is 'off'
  i = checkboxes.length - 1
  while i >= 0
    j = 0
    while j < current_on.length
      if checkboxes[i] == current_on[j]
        checkboxes.splice i, 1
      j++
    i--
  current_off = checkboxes

  $(current_on).each ->
    if $(this).prop('checked') != true
      changed.push('changed')
      remove.push($(this).val())

  $(current_off).each ->
    if $(this).prop('checked') == true
      changed.push('changed')
      add.push($(this).val())

  if changed.length > 0
    $(preview_button[0]).attr('disabled', false)
    add_lists = add.join(',')
    $(preview_button[0]).attr('data-add', add_lists)
    remove_lists = remove.join(',')
    $(preview_button[0]).attr('data-remove', remove_lists)
  else
    $(preview_button[0]).attr('disabled', true)
    $(preview_button[0]).attr('data-remove', '')
    $(preview_button[0]).attr('data-add', '')


## Submit WL/BL changes to see WBRS score preview
window.preview_wbrs_score = (button) ->
  dropdown = $(button).parents('.dispute-wlbl-adjust-wrapper')[0]
  projected_score = $(dropdown).find('.wlbl-projected-entry-wbrs')
  entry_row = $(button).parents('.research-table-row-wrapper')
  entry = $(entry_row[0]).find('.entry-data-content')
  entry_content = $(entry[0]).text().trim()
  add_lists = []
  remove_lists = []
  add = $(button).attr('data-add')
  remove = $(button).attr('data-remove')

  if add != ''
    add_lists = add.split(',')
  if remove != ''
    remove_lists = remove.split(',')

  data = {
    url: entry_content
    add: add_lists
    remove: remove_lists
  }

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/project_new_score'
    method: 'POST'
    data: data
    error_prefix: 'Error getting WBRS preview score.'
    dataType: 'json'
    success: (response) ->
      response = JSON.parse(response)
      $(projected_score[0]).text(response.score)
    error: (response) ->
      console.log(response)
  )


## Reset checkboxes and score to current settings
window.reset_score_preview = (button) ->
  dropdown = $(button).parents('.dispute-wlbl-adjust-wrapper')[0]
  projected_score = $(dropdown).find('.wlbl-projected-entry-wbrs')
  checkboxes = $(dropdown).find('.wl-bl-list-inline')
  preview_button = $(dropdown).find('.preview-wbrs-button')
  current_on = []
  current_off = []

  # Grab original 'current' lists
  current_lists = $($(dropdown).find('.wlbl-entry-wlbl')[0]).text()
  list = current_lists.split(', ')

  # If current entry isn't on a list, all toggles should be 'off'
  if current_lists == "Not on a list"
    $(checkboxes).each ->
      $(this).prop('checked', false)
  else
    $(checkboxes).each ->
      checkbox = this
      val = $(checkbox).val()
      $(list).each ->
        current = this.toString()
        if current == val
          current_on.push(checkbox)

  # Any checkbox that doesn't match the current lists is 'off'
  i = checkboxes.length - 1
  while i >= 0
    j = 0
    while j < current_on.length
      if checkboxes[i] == current_on[j]
        checkboxes.splice i, 1
      j++
    i--
  current_off = checkboxes

  # Empty projected score box
  $(projected_score[0]).text('')

  # Make checkboxes be on or off depending on original lists
  $(current_on).each ->
    $(this).prop('checked', true)
  $(current_off).each ->
    $(this).prop('checked', false)

  # Reset preview button to original state
  $(preview_button[0]).attr('disabled', true)
  $(preview_button[0]).attr('data-remove', '')
  $(preview_button[0]).attr('data-add', '')

  # Reset to original state for all threat category checkboxes
  tc_cbs = $(dropdown).find('.wlbl_thrt_cat_id')
  tc_array = $(dropdown).find('.wlbl-threat-cat-inline').text().trim().split(', ')
  $(tc_cbs).prop('checked', false)

  # BL? then reset the state of the tc cb's to orig state
  if current_lists.includes('BL-')
    $(dropdown).find('.threat-cat-cell').each ->
      curr_tc = $(this)
      $(tc_array).each (i, value) ->
        if value == $(curr_tc).text().trim()   # 'bl-weak == bl-weak'
          $(curr_tc).find(':checkbox').prop('checked', true)

  else  # WL or no list, clean slate the tc's
    $(dropdown).find('.threat-cat-row').addClass('hidden')
    $(tc_cbs).prop('checked', false)


#### WL/BL HISTORY ####

## Fetch WL/BL submission history of an entry
window.wlbl_history_dialog = (id) ->

  if isFinite(id)
    data = {'id': id}
  else
    data = {'entry': id}

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/wlbl_history'
    method: 'GET'
    headers: headers
    data: data
    success: (response) ->
      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        alert(json.error)
      else
#      #parse this json properly
        history_dialog_content = '<div class="dialog-content-wrapper">' +
          '<table class="history-table"><thead><tr><th>WL/BL Result</th><th>State</th><th>Comment</th><th>Date</th></tr></thead>' +
          '<tbody>'
        for entry in json.data
          entry_string = "" +
            '<tr>' +
            '<td>' + entry.list_type + '</td>' +
            '<td>' + entry.state + '</td>' +
            '<td>' + entry.note + '</td>' +
            '<td>' + entry.date + '</td>' +
            '</tr>'
          history_dialog_content += entry_string

        history_dialog_content += '</tbody></table>'
        #
        if $("#history_dialog").length
          history_dialog = this
          $("#history_dialog").html(history_dialog_content)
          $('#history_dialog').dialog('open')
        else
          history_dialog = '<div id="history_dialog" title="WL/BL History"></div>'
          $('body').append(history_dialog)
          $("#history_dialog").html(history_dialog_content)
          #$('#history_dialog').append(history_dialog_content)
          $('#history_dialog').dialog
            autoOpen: false
            minWidth: 600
            position: { my: "right top", at: "right top", of: window }
          $('#history_dialog').dialog('open')#
    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)


# WL/BL dropdowns checkbox validation logic, these get added to the adjust wl/bl dropdowns on page load
window.add_wlbl_threat_cat_listeners = () ->
  wlbl_dropdowns = $('.dropdown-menu .dispute-wlbl-adjust-wrapper')

  # clean slate all adjust wl/bl dropdowns
  $('#index-adjust-wlbl, #wlbl_entries_button, .bfrp-inline-wlbl-button').click ->
    $(wlbl_dropdowns).find('input:checkbox').prop('checked', false)
    $(this).next('.dropdown-menu').find('.lists-row').removeClass('hidden')

  # bulk adjust click, clean slate
  $('#index-adjust-wlbl, #wlbl_entries_button').click ->
    dd = $(this).next('.dropdown-menu')
    $(dd).find('#wlbl-add').prop('checked', true)
    $(dd).find('input:checkbox').prop('checked', false)
    $(dd).find('.dropdown-submit-button').prop('disabled', true)
    $(dd).find('.tc-replace-note, .threat-cat-row, .replace-tc-radio').addClass('hidden')

  # research rows: on page load, verify we're on research tab or bfrp, and then verify the wl/bl has text
  if ($('#research-tab').length or $('.reputation-research-search-wrapper').length) and $('.wlbl-table-result').text().trim() != ''
    $('.research-table-row').each ->
      ip_uri = $(this).find('.entry-data-content').text().trim()
      tc_area = $(this).find('.wlbl-tc-research-span')

      # threat category(s) - uses a separate API call - needs to be handled asynchronously (w/ a js promise)
      tc_promise = new Promise (resolve, reject) ->
        tc_json = get_threat_categories(ip_uri)  # inside each row, get a promise for the tc's for this uri on page load
        if tc_json then resolve tc_json

      tc_promise.then (result) ->
        {threat_categories} = JSON.parse(result)
        if threat_categories.length == 0
          tc_str = '<span class="threat-cat-no-data">No Category</span>'
        else tc_str = threat_categories.join(', ')

        tc_area.html(tc_str)  # do the actual placement of the threat cat

      .then null, (err) ->
        tc_area.html('<span class="error-threat-cat"></span>')

  # click on the label in a tc cell, toggle the cb
  $('.dispute-wlbl-adjust-wrapper .threat-cat-cell:not(input)').click ->
    $(this).find('input:checkbox').click()

  # after a click inside a wl/bl dropdown, lets handle wl/bl + tc validation for bulk or inline adjust wl/bl
  $('.dispute-wlbl-adjust-wrapper input').click ->
    cb_class = ''
    cb_value = $(this).attr('value')

    if $(this).prop('class').length
      cb_class = $(this).prop('class').split(' ')[0]
    else cb_class = ''

    dropdown_id = '#' + $(this).closest('.dropdown-menu').attr('id')  # get the dropdown id for the input just clicked

    $(dropdown_id).ready ->
      lists_row = $(this).find('.lists-row')
      wl_num = $(this).find('.lists-row input[value^="WL-"]:checked').length
      bl_num = $(this).find('.lists-row input[value^="BL-"]:checked').length
      tc_row = $(this).find('.threat-cat-row')
      tc_num = $(this).find('.threat-cat-row input:checked').length
      add_radio = $(this).find('#wlbl-add')
      remove_radio = $(this).find('#wlbl-remove')
      replace_radio = $(this).find('#wlbl-replace')
      submit_button = $(this).find('.dropdown-submit-button')
      tc_note_max = $(this).find('.threat-cat-required')
      tc_note_replace = $(this).find('.tc-replace-note')

      enableSubmit = () -> $(submit_button).prop('disabled', false)
      disableSubmit = () -> $(submit_button).prop('disabled', true)

      clearAllInputs = () ->
        $(wlbl_dropdowns).find('input:checkbox').prop('checked', false)
        $(wlbl_dropdowns).find('.tc-replace-note').addClass('hidden')
        disableSubmit()

      if cb_value.includes('BL-') and bl_num > 0
        unless $(dropdown_id).find('#wlbl-remove').prop('checked')
          tc_row.removeClass('hidden')

      else if cb_value.includes('BL-') and bl_num == 0 and add_radio.prop('checked')
        $(dropdown_id).find('.threat-cat-row input').prop('checked', false)
        tc_row.addClass('hidden')

      # Add / Remove - clean slate on click, .merge() allows selecting mult vars in jquery
      $.merge(add_radio, remove_radio).click ->
        lists_row.removeClass('hidden')
        $.merge(tc_row, tc_note_replace).addClass('hidden')
        clearAllInputs()

      replace_radio.click ->
        tc_text_array = $('.wlbl-threat-cat').text().trim().split(', ')  # tc_text_array is the text array of 'Bogon', 'Botnets', etc
        tc_cell_array = $(dropdown_id).find('.threat-cat-cell').toArray()
        $.merge(lists_row, tc_note_max).addClass('hidden')
        $.merge(tc_row, tc_note_replace).removeClass('hidden')
        $(dropdown_id).find('.dropdown-menu .dispute-wlbl-adjust-wrapper input:checkbox').prop('checked', false)

        disableSubmit()

        # get a filtered array of tc's to pre-toggle the checkboxes
        tc_toggle_array = tc_cell_array.filter((entry) ->  # entry of tc html elements, entry is an html element w/ label + input
          entry_matches = false
          $(tc_text_array).each (i, value) ->
            if value == $(entry).text().trim() then entry_matches = true
          if entry_matches then return entry
        )

        $(tc_toggle_array).each -> $(this).find('input:checkbox').prop('checked', true)

      if add_radio.prop('checked') then tc_note_max.removeClass('hidden') else tc_note_max.addClass('hidden')

      # if change is checked and no tc's, then no bl's should be checked, ensure this
      if replace_radio.prop('checked') and tc_num == 0
        $(this).find('.lists-row input[value^="BL-"]').prop('checked', false)

      # this is the class for tc cb's
      if cb_class.includes('wlbl_thrt_cat_id')
        if replace_radio.prop('checked') and tc_num == 0
          tc_note_replace.removeClass('hidden')
        else if tc_num > 5
          $(this).find('.five-note').addClass('required-bold')
        else if tc_num <= 5 and tc_num > 0
          $(this).find('.five-note').removeClass('required-bold')

      # every input click, disable submit unless certain criteria is met
      disableSubmit()

      # scenarios to enable the submit button
      conditionsArray = [
        wl_num > 0 && bl_num == 0 && tc_num == 0,
        bl_num > 0 && tc_num > 0 && tc_num <= 5,
        add_radio.prop('checked') && bl_num > 0 && tc_num > 0 && tc_num <= 5,
        remove_radio.prop('checked') && bl_num > 0,
        replace_radio.prop('checked') && bl_num == 0 && tc_num == 0,  # no tc's? no bl's either then, let them submit
        replace_radio.prop('checked') && tc_num > 0 && tc_num <= 5  # user can change existing tc's
      ]

      if conditionsArray.indexOf(true) >= 0
        enableSubmit()


# on page load, add the wl/bl + tc input event listeners inside the dropdowns
$ ->
  add_wlbl_threat_cat_listeners()

