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

  # clear all checkboxes on every click, hide the tc row
  # clear all checkboxes on every click, hide the tc row
  # clear all checkboxes on every click, hide the tc row
  $('.dropdown-menu .wlbl-threat-cat-inline').html('')
  $('.dropdown-menu input:checkbox').prop('checked', false)
  $('.threat-cat-row').addClass('hidden')

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
          switch String(this)
            when 'BL-weak', 'BL-med', 'BL-heavy'
              # for bl's, show the threat cat row
              $(dropdown).find('.threat-cat-row').removeClass('hidden')
              # get and set the threat categories with a promise

              tc_promise = new Promise (resolve, reject) ->
                tc_json = get_threat_categories(entry_content)
                if tc_json then resolve tc_json  # resolve goes to .then() below

              tc_promise.then (result) ->
                {threat_categories} = JSON.parse(result)
                if threat_categories.length == 0
                  tc_str = '<span class="threat-cat-no-data">No Category</span>'
                else tc_str = threat_categories.join(', ')

                # step 1, place the threat cats in the html after the promise is ready
                $(tc_cell).html(tc_str)

                # step 2, toggle the tc checkboxes in the .threat-cat-row
                $(dropdown).find('.threat-cat-cell').each ->
                  curr_text = $(this).text().trim()
                  curr_input = $(this).find('input:checkbox')
                  $(threat_categories).each (i, value) ->
                    if value == curr_text then curr_input.prop('checked', true)

        $(wbrs_score).text(wbrs)
        $(wlbl_list[0]).text(response.data.join(', '))
        $(submit_button[0]).attr('disabled', true)
      else
        $(wbrs_score).text(wbrs)
        $(wlbl_list[0]).text('Not on a list')
        $(submit_button[0]).attr('disabled', true)
    $(comment).text(comment_text)
    error: (response) ->
      popup_response_error(response, 'Error retrieving WL/BL Data')
  )


## Populating the toolbar Adjust WL/BL dropdown
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

          # Bulk adjust threat cat placement (waypoint)
          place_threat_category(ip_uri, 'bulk')

          comment = entry['notes']
          if list_types
            list_types = entry['list_types'].join(', ')
          else
            list_types = ''
            wbrs_score = wbrs
          if wbrs_score == null
            wbrs_score = '<span class="missing-data text-left">No Score</span>'
          if comment == null
            comment = ''

          # TODO: LOGIC ERROR HERE FOR LAST ROW (REPEATS SAME SCORE FOR ALL ROWS), NEEDS CORRECTION IN SEPARATE TICKET
          $(tbody).append('<tr class="wlbl-dropdown-row">' + '<td class="wlbl-entry-content">' + ip_uri + '</td><td class="wlbl-entry-wlbl">' + list_types + '</td>' + '<td class="wlbl-current-entry-wbrs text-center">' + wbrs_score + '</td>' + '<td class="wlbl-threat-cat"></td>')

        comment_box.text(comment_trail)
      error: (response) ->
        std_msg_error( 'Error retrieving WL/BL Data', response)
    )
  else
    std_msg_error('No rows selected', ['Please select at least one entry row.'])
    return false



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
    thrt_cat_ids = [ $(dropdown).find('.wlbl_thrt_cat_id').val() ]

    if $(entries).length > 0
      $(entries).each ->
        entry = $(this).text()
        ip_uris.push(entry)

    data = {ip_uris: ip_uris, list_types: list_types, note: wlbl_comment, thrt_cat_ids: thrt_cat_ids}

    # dbinebri: here is where the add/remove forms are being handled
    # dbinebri: here is where the add/remove forms are being handled
    # dbinebri: here is where the add/remove forms are being handled
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
    else if $('#wlbl-add').prop('checked') == true or $('#wlbl-change').prop('checked') == true
      std_msg_ajax(
        url: '/escalations/api/v1/escalations/webrep/disputes/bulk_rule_ui_wlbl_add'
        method: 'POST'
        data: data
        success: (response) ->
          std_msg_success("The following entries have been added to " + list_types, ip_uris)
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
  list = current_lists.split(',')

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


#### THREAT CATEGORY - uses a separate API call - needs to be handled asynchronously ####
# use this uri + place the threat cat(s) in adjust wl/bl bulk dropdown, inline dropdown, or research row (bfrp / show page)
window.place_threat_category = (ip_uri, type, wrapper_id) ->
  # use a promise for the threat cat api call, could take up to 1-2 seconds
  tc_promise = new Promise (resolve, reject) ->
    tc_json = get_threat_categories(ip_uri)
    if tc_json
      resolve tc_json  # resolve goes to .then() below

  tc_promise.then (result) ->
    {threat_categories} = JSON.parse(result)

    bulk_tc = $('.wlbl-threat-cat')
    inline_tc = $('.wlbl-threat-cat-inline')
    inline_wlbl_list = $('.wlbl-entry-wlbl')  # this is the wl/bl list, not a tc list
    bfrp_search = $('.reputation-research-search-wrapper')

    research_row_full = $('.wlbl-and-tc-area')  # this is the wl/bl area inside of a research row (wbrs row)
    research_row_left = $('.wlbl-table-result')
    research_row_right = $('.wlbl-tc-research-span')

    if threat_categories.length == 0
      tc_str = '<span class="threat-cat-no-data">No Category</span>'
    else tc_str = threat_categories.join(', ')

    # type of place to add the threat cat(s): bulk, inline, or research row on page-load (show page or bfrp)
    switch type
      when 'bulk'
        # REFACTOR THIS OUT
        bulk_tc.html(tc_str)
        if $('.wlbl-entry-wlbl').length > 0 and $('.wlbl-entry-wlbl').text().trim().includes('BL-')
          $('.change-tc-radio').removeClass('hidden')  # show the 'change threat categories' radio button in dropdown
        if $('.wlbl-entry-wlbl').length > 0 and ($('.wlbl-entry-wlbl').length > 0 and $('.wlbl-entry-wlbl').text().trim() == '')
          bulk_tc.empty()
        if bfrp_search.length > 0 and $('.wlbl-table-result').text().trim() == ''
          $('.wlbl-threat-cat').remove()
        if $('#research-tab').length > 0 and $('.wlbl-table-result').text().trim() == ''
          $('.wlbl-threat-cat').remove()

      when 'research'
        if bfrp_search.length > 0 and research_row_left.text().trim() == ''  # on bfrp page
          research_row_right.html('').remove()   # if on bfrp and no wl's or bl's, then no tc's should show (1234computer.com issue)
          $('.dropdown-menu .wlbl-threat-cat-inline').remove()  #    use a $(wrapper_id)
        else if bfrp_search.length > 0 and research_row_left.text().includes('BL')  # on research tab show page
          research_row_right.html(tc_str)
          research_row_full.addClass('ensure-tc-width')  # ensure enough width for all lists + TC's
        else research_row_right.html(tc_str)

  # error handling for the json response, leave the empty error span
  .then null, (err) ->
    tc_elements = '.wlbl-threat-cat, .wlbl-threat-cat-inline, .wlbl-tc-research-span'
    $(tc_elements).html('<span class="error-threat-cat"></span>')



# WL/BL dropdowns checkbox validation logic, these get added for these dropdowns on page load
window.addWlBlListeners = () ->
  # change_radio only exists if 1 or more BL's exist
  $('#wlbl-change').click ->
    $('.lists-row, .tc-change-note').addClass('hidden')
    $('.threat-cat-row').removeClass('hidden')
    $('.dropdown-menu input:checkbox').prop('checked', false)
    $('.dropdown-submit-button').prop('disabled', true)

  $('#index-adjust-wlbl').click ->
    $('.threat-cat-row, .tc-change-note, .change-tc-radio').addClass('hidden')
    $('.lists-row').removeClass('hidden')
    $('.dropdown-menu input:checkbox').prop('checked', false)
    $('.dropdown-submit-button').prop('disabled', true)

  # after a click inside wl/bl dropdown, fig out where you are, get the dropdown id for the validation inside that specific dropdown
  $('.dispute-wlbl-adjust-wrapper input').click ->
    cb_value = $(this).attr('value')
    cb_class = ''
    dropdown_id = ''

    if $(this).prop('class').length > 0
      cb_class = $(this).attr('class').split(' ')[0]  # first class for that element

    # define the wrapper id, either a dropdown id or a row id, depending where a threat cat needs to go
    dropdown_id = '#' + $(this).closest('.dropdown-menu').attr('id')  # get the dropdown id for the input just clicked

    # below this line, $(this) refers to the active dropdown, so we don't select all existing dropdowns in the dom
    $(dropdown_id).ready ->
      wl_num = $(this).find('.lists-row input[value^="WL-"]:checked').length
      bl_num = $(this).find('.lists-row input[value^="BL-"]:checked').length
      tc_row = $(this).find('.threat-cat-row')
      lists_row = $(this).find('.lists-row')
      tc_num = $(this).find('.threat-cat-row input:checked').length
      add_radio = $(this).find('#wlbl-add')
      remove_radio = $(this).find('#wlbl-remove')
      change_radio = $(this).find('#wlbl-change')
      all_cbs = $(this).find('.dispute-wlbl-adjust-wrapper input:checkbox')
      submit_button = $(this).find('.dropdown-submit-button')
      tc_note = $(this).find('.threat-cat-required')

      enableSubmit = () -> $(submit_button).prop('disabled', false)
      disableSubmit = () -> $(submit_button).prop('disabled', true)

      clearAllInputs = () ->
        $(all_cbs).prop('checked', false)
        $('.tc-change-note').addClass('hidden')
        disableSubmit()

      # BL click? show/hide the threat cat row if 'Add to list' is toggled
      if cb_value.includes('BL-') and bl_num > 0
        unless $(dropdown_id).find('#wlbl-remove').prop('checked') == true
          # if the remove is toggled inside this dropdown, dont do below
          tc_row.removeClass('hidden')

      else if cb_value.includes('BL-') and bl_num == 0 and add_radio.prop('checked') == true
        $('.threat-cat-row input').prop('checked', false)
        tc_row.addClass('hidden')

      # Add / Remove - clean slate on either click
      add_radio.click ->
        $('.tc-change-note').addClass('hidden')
        lists_row.removeClass('hidden')
        tc_row.addClass('hidden')
        clearAllInputs()

      remove_radio.click ->
        $('.tc-change-note').addClass('hidden')
        lists_row.removeClass('hidden')
        tc_row.addClass('hidden')
        clearAllInputs()

      change_radio.click ->
        # pre-toggle all the tc cb's
        $('.tc-change-note').removeClass('hidden')

        tc_array = $('.wlbl-threat-cat').text().trim().split(', ')
        $(dropdown_id).find('.threat-cat-cell').each ->
          curr_text = $(this).text().trim()
          curr_input = $(this).find('input:checkbox')
          $(tc_array).each (i, value) ->
            if value == curr_text then curr_input.prop('checked', true)  # toggle all the tc cb's
        disableSubmit()

      # show/hide the note about 5 tc's when you are Adding to list
      if add_radio.prop('checked') then tc_note.removeClass('hidden') else tc_note.addClass('hidden')

      # Change Threat Categories:
      # if change is checked and no tc's, then no bl's should be checked, ensure this
      if change_radio.prop('checked') and tc_num == 0
        $(this).find('.lists-row input[value^="BL-"]').prop('checked', false)

      # tc cb click inside change tc's? show the "bls will be removed" note + clear the bl cb's in background
      # this submit form (change is checked) will simply function as if "add to list" is toggled
      if cb_class.includes('wlbl_thrt_cat_id') and change_radio.prop('checked') and tc_num == 0
        $('.tc-change-note').removeClass('hidden')  # Note: No threat categories are checked, if you Submit
        bl_num = 0  # set the blacklists all to zero, if tc_num is 0, bl_num is 0

      # threat category checkbox click: if already 5 tc's checked, bold the note, max is 5
      if cb_class.includes('wlbl_thrt_cat_id') and tc_num > 5
        $(this).find('.five-note').addClass('required-bold')
      else $(this).find('.five-note').removeClass('required-bold')

      # every click, disable submit unless certain criteria is met
      disableSubmit()

      # scenarios to enable the submit button
      conditionsArray = [
        wl_num > 0 && bl_num == 0 && tc_num == 0,
        bl_num > 0 && tc_num > 0 && tc_num <= 5,
        add_radio.prop('checked') && bl_num > 0 && tc_num > 0 && tc_num <= 5,
        remove_radio.prop('checked') && bl_num > 0,
        change_radio.prop('checked') && bl_num == 0 && tc_num == 0,  # no tc's? no bl's either then, let them submit
        change_radio.prop('checked') && tc_num > 0 && tc_num <= 5  # user can change existing tc's
      ]

      if conditionsArray.indexOf(true) >= 0
        enableSubmit()

  # PAGE LOAD - RESEARCH TAB - CONFIRMED WORKING - LEAVE HERE OR REFACTOR?
  if $('#research-tab').length > 0
    setTimeout ( ->
      row_id = '#' + $(this).siblings('.dropdown-menu').attr('id')
      ip_uri = $('.dispute-entry-ip-uri').text().trim().split(',')[0]
      unless $('.wlbl-table-result').text().trim() == ''   # handle the no-bl don't show tc's (1234computer.com issue)
        place_threat_category(ip_uri, 'research', '')
    ), 1500

  # PAGE LOAD - BFRP RESEARCH - LEAVE HERE OR REFACTOR?
  if $('.reputation-research-search-wrapper').length > 0
    setTimeout ( ->
      ip_uri = $('.searched-for-url').text().trim().split(',')[0]
      place_threat_category(ip_uri, 'research', '')
    ), 1500

# on page load, add the wl/bl + tc input event listeners inside the dropdowns
$ ->
  addWlBlListeners()

