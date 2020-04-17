######################################################################################
# FUNCTIONS FOR POPULATING, SUBMITTING, ETC. WBRS WL/BL, THREAT CATEGORY INFORMATION
######################################################################################

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

  wlbl_list = $(dropdown_wrapper).find('.wlbl-entry-wlbl')
  tbody = $(dropdown_wrapper).find('table.dispute_tool_current').find('tbody')
  comment_box = $(dropdown_wrapper).find('.adjust-wlbl-input')
  comment_textarea = $(dropdown_wrapper).find('.note-input')

  # Clear out any residual data
  $(tbody).empty()
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

  # Clean slate this attribute
  $(dropdown_wrapper).removeAttr('data-disable-submit')

  # Clean slate these bulk wl/bl cb enabled/disabled states
  $(dropdown_wrapper).find('.wl-bl-list-inline:checkbox').prop('disabled',false).closest('li').removeClass('grayed-out')

  # Pull the entry content out
  if (entries_checked.length > 0)
    entries = []
    wbrs = ''
    comment_trail = ''
    comment_array = []
    closed_entries = []
    entry_ids = []
    $(entries_checked).each ->
      # Slightly different structure to get the actual entry content
      if row == '.index-entry-row'
        entry_row = $(this).parents(row)[0]
        entry_content = $(entry_row).find('.entry-col-content').text().trim()
        entry_case_id = $(entry_row).attr('data-case-id')
        wbrs = $(entry_row).find(current_wbrs).text()
        comment_array.push('#' + entry_case_id + ' - ' + entry_content)
        status = $(entry_row).find('.entry-col-status').text().trim()
        entry_id = $(entry_row).find('.dispute-entry-checkbox').attr('id')
      else if row == '.research-table-row'
        entry_row = $(this).parents(row)[0]
        entry_content = $(entry_row).find('.entry-data-content').text().trim()
        wbrs = $(entry_row).find(current_wbrs).text()
        status = $(entry_row).find('.entry-data-status').text().trim()

      # add this entry info to 'entries' array
      entries.push(entry_content)

      # if this is a closed entry, add to closed_entries array
      if status.toLowerCase().includes('resolved')
        closed_entries.push(entry_content)

      # if there are closed entries in this bulk dropdown, add an attribute to disable Submit
      if closed_entries.length > 0
        $(dropdown_wrapper).attr('data-disable-submit','disable')

    data = {'entries': entries}

    if page == "show"
      comment_trail = '\n \n------------------------------- \nBULK SUBMISSION: \n #' + case_id + ' - ' + entries.join(', ')
    else if page == "research"
      comment_trail = '\n \n------------------------------- \nRESEARCH BULK SUBMISSION: \n' + entries.join('\n')
    else if page == "index"
      comment_trail = '\n \n------------------------------- \nBULK SUBMISSION: \n' + comment_array.join('\n')

    # Add some loading text while the tbody gets built
    $(tbody).empty().html('<tr class="loading-rows"><td>Loading...<div class="mini-loader"></div></td></tr>')

    # Clean slate the dropdown
    $(comment_textarea).val(comment_trail)
    $(dropdown_wrapper).find('.disabled-submit-msg').addClass('hidden')

    # disable submit if any closed entries selected
    if $(dropdown_wrapper).attr('data-disable-submit') == 'disable'
      $(dropdown_wrapper).find('.disabled-submit-msg').removeClass('hidden')

    console.log 'YOU ARE IN BULK ADJUST, DO THE AJAX CALL...'

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/bulk_rule_ui_wlbl_get_info_for_form'
      method: 'POST'
      data: data
      success: (response) ->
        console.log 'RESPONSE:'
        console.log response
        response = JSON.parse(response)
        for entry in response   # wait until tc's are resolved to write out the full table rows
          tc_promise = new Promise (resolve, reject) ->
            tc_json = get_threat_categories(entry.ip_uri)
            if tc_json
              resolve(tc_json)  # resolve goes to .then() below
          .then(build_tc_row.bind(null, entry, tbody))
          comment_box.text(comment_trail)

      error: (response) ->
        std_msg_error('Error retrieving WL/BL Data in Bulk Adjust', response)

      complete: () ->
        # slight delay to ensure row order, refactor when time avail
        setTimeout (->
          bulk_order_rows()  # first, order the rows
        ),600
    )
  else
    std_msg_error('No rows selected', ['Please select at least one entry row.'])
    return false

  # build the top blue dispute rows with wl/bl's and threat cats, ensures the row gets built correctly (KH refactor)
  window.build_tc_row = (entry, tbody, result) ->

    { threat_categories } = JSON.parse(result)
    { ip_uri, list_types, wbrs_score, comment } = entry

    console.log 'THREAT CATEGORIES IF ANY:'
    console.log threat_categories

    # first row is built? hide the loading row
    $(tbody).find('.loading-rows').addClass('hidden')

    tc_str = ''
    if threat_categories?
      tc_str = threat_categories.join(', ')

    if list_types
      list_types = entry['list_types'].sort().reverse().join(', ')  # sort by weak, then med, then heavy
      if list_types.includes('BL-') && !$('body').hasClass('research-action')
        $('.replace-tc-radio').removeClass('hidden')  # show 'replace' radio if bl exists and NOT on bfrp
    else
      list_types = ''
      wbrs_score = wbrs
    if !wbrs_score || isNaN(wbrs_score)   # if no score or not a number
      wbrs_score = '<span class="missing-data">No score</span>'

    if !comment then comment = ''

    # ensure the 'not on a list' text is formatted correctly
    if list_types.length == 0
      list_types = "<span class='missing-data'>Not on a list</span>"


    table_row =
      "<tr class='wlbl-dropdown-row'>
      <td class='wlbl-entry-content'>#{ip_uri}</td>
      <td class='wlbl-entry-wlbl'>#{list_types}</td>
      <td class='wlbl-current-entry-wbrs'>#{wbrs_score}</td>
      <td class='wlbl-threat-cat'>#{tc_str}</td>
      </tr>"

    $(tbody).append(table_row)


# order the rows for bulk dropdown, same order on left cbs as on right dd rows
window.bulk_order_rows = () ->
  if $('#wlbl_adjust_entries_index').length > 0  # index dropdown
    curr_dd = '#wlbl_adjust_entries_index'
    left_cbs = '#disputes-index .dispute-entry-checkbox:checked'
    url_entry = '.entry-col-content'
  else  # show page dropdown and bfrp dropdown bulk
    curr_dd = '#wlbl_adjust_entries'
    left_cbs = '#disputes-research-table .dispute_check_box:checked'
    url_entry = '.entry-data-content'

  $(left_cbs).each (i) ->  # add the order ids to left and right sides
    ip_uri = $(this).closest('tr').find(url_entry).text().trim()
    if $('.bfrp-table').length > 0
      ip_uri = $(this).closest('tr').find('.entry-data-content').text().trim()
    $(this).closest('tr').attr('data-order-id', i)  # add row-id to the left, this works on bfrp confirmed

    if $('body').hasClass('index-action')
      curr_entry_id = 'wlbl-entry-id-' + $(this).attr('id')
    else if $('body').hasClass('show-action')
      curr_entry_id = 'wlbl-entry-id-' + $(this).attr('data-entry-id')
    else if $('body').hasClass('research-action')
      curr_entry_id = $(this).attr('class').split(' ').pop()
      # for the bulk dropdowns on bfrp, ensure unique classes in dropdown, bfrp bulk dd'S
      curr_entry_id = curr_entry_id.replace('-result-','-dd-result-')

    # comparing the http/non-http versions of these urls/domains
    $(curr_dd).find('.wlbl-entry-content').each ->
      curr_text = $(this).text().trim()
      if ip_uri.includes(curr_text)
        $(this).closest('tr').attr('data-order-id', i)  # add row-id to the right

        # ensure always adding a unique -dd- class-id each time to bulk dropdown
        $(this).closest('tr').find('td.wlbl-entry-wlbl').attr('class','wlbl-entry-wlbl').addClass(curr_entry_id)

  table_dd = $(curr_dd).find('tbody')
  rows = $(table_dd).find('tr')

  # basic sort by id/integer
  rows.sort (a, b) ->
    x = $(a).attr('data-order-id')
    y = $(b).attr('data-order-id')
    x - y
  $(rows).each (i, row) -> table_dd.append(row)

  # bfrp > after sorted, for each entry add a numerical "bfrp-dd-result-0" for tests
  $(curr_dd).find('.wlbl-entry-wlbl').each (i) ->
    # wlbl-entry-id-1 for show page, bfrp-dd-result-0 for research page for existing iteration conventions
    $(this).attr("class","wlbl-entry-wlbl wlbl-entry-id-#{i+1} bfrp-dd-result-#{i}")
    $(this).parent().removeAttr('data-order-id')



#### POPULATING CURRENT WL/BL LISTS ####

## INLINE - Populating the inline Adjust WL/BL dropdown for
## research page and research tab (individual submission form)
window.get_current_wlbl = (button) ->
  # Get entry content
  research_row = $(button).parents('.research-table-row')[0]
  entry_wrapper = $(research_row).find('.entry-data-content')[0]
  entry_content = $(entry_wrapper).text().trim()
  wbrs = $($(research_row).find('.entry-data-wbrs-score')[0]).text()
  tc_cell = $($(research_row).find('.wlbl-threat-cat-inline')[0])
  tcs_from_row = ''  # grab tc's from the research row (show or bfrp) for the dd

  # On show page, if status is closed, then add a sentence that says you can't do anything
  if $(research_row).find('.entry-data-status').length
    entry_status = $(research_row).find('.entry-data-status').text().trim()

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
  comment_textarea = $(dropdown).find('.note-input')
  tc_row = $(dropdown).find('.threat-cat-row')
  list_cbs = $(dropdown).find('.wl-bl-list-inline:checkbox')
  wl_weak = $(dropdown).find('.wl-weak-checkbox')
  wl_med = $(dropdown).find('.wl-med-checkbox')
  wl_heavy = $(dropdown).find('.wl-heavy-checkbox')
  bl_weak = $(dropdown).find('.bl-weak-checkbox')
  bl_med = $(dropdown).find('.bl-med-checkbox')
  bl_heavy = $(dropdown).find('.bl-heavy-checkbox')

  # Clearing data to start in case user has page open for a while and data needs to be regrabbed
  $(wlbl_list[0]).empty()
  $(wbrs_score[0]).empty()
  $(tc_cell).empty()
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

  # Add loading message while wl/bl rows are being built, this gets removed after data is loaded
  $(wlbl_list).html('<span class="loading-rows">Loading...<span class="mini-loader"></span></span>')

  # Clean slate the inline dropdowns on every dropdown click / spawn
  $(submit_button).html('Submit Changes').prop('disabled', true)
  $(comment_textarea).val(comment_text)
  $(tc_row).addClass('hidden')
  $(list_cbs).prop('disabled',false).closest('li').removeClass('grayed-out')

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
      # values will be in the format of BL-med, BL-weak, BL-heavy (same with WL)
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
            when 'BL-weak', 'BL-med', 'BL-heavy'   # entry is on a BL?
              $(dropdown).find('.threat-cat-row').removeClass('hidden')

              tc_promise = new Promise (resolve, reject) ->   # get and set the tc's with a promise
                tc_json = get_threat_categories(entry_content)
                if tc_json
                  resolve tc_json  # resolve goes to .then() below

              tc_promise.then (result) ->
                {threat_categories} = JSON.parse(result)

                ### retain this commented block for now. delete when obvious it's safe to do so.
                if threat_categories.length == 0
                  tc_str = '<span class="threat-cat-no-data">No category</span>'
                else tc_str = threat_categories.join(', ')
                $(tc_cell).html(tc_str)  # write the tc's into the dd
                ###

                $(dropdown).find('.threat-cat-cell').each ->
                  curr = $(this)  # pre-toggle the tc cb's in the tc row below
                  $(threat_categories).each (i, value) ->
                    if value == $(curr).text().trim()
                      $(curr).find('input:checkbox').prop('checked', true)

        if wbrs.trim() == 'No score'
          wbrs = "<span class='missing-data'>No score</span>"
        $(wbrs_score).html(wbrs)

        $(wlbl_list[0]).text(response.data.sort().reverse().join(', '))   # sort the lists from weak to heavy
        $('.wlbl-entry-wlbl').text(response.data.join(', '))
        if response.data.join(', ').length == 0
          $(dropdown).find('.wlbl-entry-wlbl').html('<span class="missing-data">Not on a list</span>')
        $(submit_button[0]).attr('disabled', true)

      else
        if wbrs.trim() == 'No score'
          wbrs = "<span class='missing-data'>No score</span>"
        $(wbrs_score).html(wbrs)
        $(wlbl_list[0]).html('<span class="missing-data">Not on a list</span>')
        $(submit_button[0]).attr('disabled', true)

    error: (response) ->
      popup_response_error(response, 'Error retrieving WL/BL Data')

    complete: () ->
      # show the current tc's inside the dropdown, even if no bl's present
      tcs_from_row = $(research_row).find('.wlbl-tc-research-span').html()  # from the research row, get the curr tc's
      $(dropdown).find('.wlbl-threat-cat-inline').html(tcs_from_row)  # into the dropdown, add those tc's

      # inline specific - determine if wl's OR bl's are already pre-selected, disable ability to select opposite cb's
      wl_num = $(dropdown).find('.lists-row input[value^="WL-"]:checked').length
      bl_num = $(dropdown).find('.lists-row input[value^="BL-"]:checked').length

      # clean slate the inline cb's
      $(dropdown).find(".wl-bl-list-inline:checkbox").prop('disabled',false).closest('li').removeClass('grayed-out')

      # disable opposite cb's if something is already pre-set on a list, at-a-time validation
      unless (wl_num > 0 and bl_num > 0) || (wl_num == 0 and bl_num == 0)
        if bl_num > 0 && wl_num == 0 then curr_cbs = 'WL-'
        else if wl_num > 0 && bl_num == 0 then curr_cbs = 'BL-'
        $(dropdown).find(":checkbox[value^='#{curr_cbs}']").prop('disabled',true).closest('li').addClass('grayed-out')
  )




########## SUBMISSION OF WL/BL CHANGES TO WBRS ##########

## BULK SUBMISSION of WL/BL changes - toolbar dropdown form
window.submit_bulk_wlbl = (page) ->
  data = {}
  ip_uris = []
  list_types = []
  disputes_array = []
  closed_entries = []
  wlbl_comment = ''
  dropdown = ''
  modal_action = ''

  if $('.wl-bl-list-inline:checkbox:checked').length or $('.wlbl_thrt_cat_id:checked').length
    list_types = $('.wl-bl-list-inline:checkbox:checked').map(() -> this.value).toArray()
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
    thrt_cat_array = $(dropdown).find('.wlbl_thrt_cat_id:checked')
    thrt_cat_str = ''

    $(thrt_cat_array).each ->
      thrt_cat_ids.push(parseInt($(this).val()))  # ensure this is an array of numbers, not strings
      thrt_cat_names.push($(this).parent().text().trim())

    # adjustment type - add / remove / replace
    if $('#wlbl-add').prop('checked')
      adjustment_type = 'add'
      modal_action = 'added to'
    else if $('#wlbl-remove').prop('checked')
      adjustment_type = 'remove'
      modal_action = 'removed from'
    else if $('#wlbl-replace').prop('checked')
      adjustment_type = 'replace'
      modal_action = 'updated for'

    if page == 'index'
      disputes_array = $('.dispute-entry-checkbox:checked').map(() ->
        parseInt(this.id)  # pass number to endpoint, not string
      ).toArray()
    else if page == 'show'
      $('.dispute_check_box:checked').each ->
        curr_entry_id = parseInt($(this).attr('data-entry-id'))
        disputes_array.push(curr_entry_id)


  # ADD TO LISTS BULK
  if adjustment_type == 'add' or adjustment_type == 'replace'
    console.log 'bulk scenario 1'  # index/show add/replace: use new endpoint + entry url array

    # REPLACE THREAT CATEGORIES BULK
    if adjustment_type == 'replace'
      list_types = ['BL-weak']  # hardcoded, this will be ignored on a 'replace', this is intentional

    data =
      lists: list_types  # new object, this needs to be dispute_entries (ids), not urls
      note: wlbl_comment
      thrt_cat_ids: thrt_cat_ids
      adjustment_type: adjustment_type
    endpoint = '/escalations/api/v1/escalations/webrep/disputes/bulk_wlbl_threatcat_adjust'

    # on index or show bulk (not bfrp), must use dispute entry ids array
    if $('.bfrp-table').length == 0
      data.dispute_entries = disputes_array
    else # on bfrp bulk? pass in urls, has to be done, no ids on bfrp
      data.urls = ip_uris

  # REMOVE FROM LISTS BULK
  else if adjustment_type == 'remove'
    console.log 'bulk scenario 2'  # index/show/bfrp remove: use old endpoint + entry url array
    data =
      ip_uris: ip_uris    # old object, needs to be 'ip_uris'
      list_types: list_types
      note: wlbl_comment
      thrt_cat_ids: thrt_cat_ids
    endpoint = '/escalations/api/v1/escalations/webrep/disputes/bulk_rule_ui_wlbl_remove'

  # ensure we're showing only non-duplicate lists in the modal
  unique_lists = []
  $.each list_types, (i, entry) ->
    if($.inArray(entry, unique_lists) == -1)
      unique_lists.push(entry)

  # build the confirmation modal
  modal_info_string =
    "<div class='wlbl-info-modal'><p>The following entries: </p>
      <span>#{ip_uris.join('<br>')}</span>"

  if unique_lists.length && adjustment_type != 'replace'   # replace is for TC's only
    modal_info_string +=
      "<span>Have been #{modal_action} the following WBRS Lists:
        <p>#{unique_lists.join(', ')}</p></span>"

  if thrt_cat_ids.length
    modal_info_string +=
      "<span>With the following threat categories updated:
        <p>#{thrt_cat_names.join(', ')}</p></span>"

  # finish the modal
  modal_info_string += "</div>"

  # submit ready? make sure our data object is correct
  console.log endpoint
  console.log data

  std_msg_ajax(
    url: endpoint
    method: 'POST'
    data: data
    success: (response) ->
      std_msg_success("Entries have been updated", [modal_info_string])
    error: (response) ->
      std_api_error(response, 'Error updating these entries.')
    completed: () ->
      $('.dispute-wlbl-adjust-wrapper .dropdown-submit-button').html('Submit Changes').prop('disabled', false)
  )



# INLINE ADJUST WL/BL AND THREAT CATEGORIES
window.submit_individual_wlbl = (button_tag) ->
  wlbl_form = button_tag.form;

  # endpoint expects id's to represent url's by default, passing in url's is optional but acceptable too
  dispute_entry_id = parseInt($(wlbl_form).parents('.research-table-row').attr('data-entry-id'))
  dispute_url = $(wlbl_form).parents('.research-table-row').find('.entry-data-content').text().trim()
  old_lists_str = $(wlbl_form).find('.wlbl-entry-wlbl').text()  # lists (old) for this entry
  old_lists_arr = old_lists_str.split(', ')
  curr_note = $(wlbl_form).find('.note-input').val()
  endpoint = ''
  modal_info_string = ''
  modal_action = ''
  removed_lists_arr = []
  data = []
  data_new = []
  data_old = []

  new_lists_arr = $('.wl-bl-list-inline:checkbox:checked').map(() ->
    this.value
  ).toArray()
  new_lists_str = new_lists_arr.join(', ')

  # inline specific - figure out which lists have been removed in the fancy-sliders using filter
  removed_lists_arr = old_lists_arr.filter((list) ->
    !new_lists_arr.includes(list))

  thrt_cat_ids = []
  thrt_cat_names = []
  thrt_cat_array = $(wlbl_form).find('.wlbl_thrt_cat_id:checked')
  thrt_cat_str = ''

  $(thrt_cat_array).each ->
    thrt_cat_ids.push(parseInt($(this).val()))  # fix to ensure passing an array of numbers
    thrt_cat_names.push($(this).parent().text().trim())

  # start the adjustment type super-specific variables init, double-api call scenario (add + remove simultaneous)
  adjustment_type = ''
  second_adjustment_type = false  # CHANGE TO BOOL, this only gets used if user does add + remove at same time for inline
  old_length = old_lists_arr.length
  new_length = new_lists_arr.length
  tc_length = thrt_cat_ids.length

  if old_lists_str == '' || old_lists_str.includes('Not')
    old_length == 0


  # FIRST ADJUSTMENT_TYPE
  if (new_length > old_length || new_length == old_length) and tc_length == 0
    adjustment_type = 'add'
    modal_action = 'added to'
  else if new_length == old_length and tc_length > 0
    adjustment_type = 'replace'
    modal_action = 'updated for'
    if $('body').hasClass('research-action')  # bfrp doesn't do 'replace' on new endpoint
      adjustment_type = 'add'
      modal_action = 'added to'
  else if new_length < old_length and tc_length == 0
    adjustment_type = 'remove'
    modal_action = 'removed from'


  # SECOND_ADJUSTMENT_TYPE (if needed, this is rare
  # TODO: CLEAN THIS UP
  if old_lists_str.includes('BL') && new_lists_str.includes('WL') && !old_lists_str.includes('WL') && !new_lists_str.includes('BL')
    second_adjustment_type = true
    console.log 'inline scenario 4: you were on BL(s), but now you are removing BL(s) and adding WL(s)'

  else if old_lists_str.includes('WL') && new_lists_str.includes('BL') && !old_lists_str.includes('BL') && !old_lists_str.includes('BL') && !new_lists_str.includes('WL')
    second_adjustment_type = true
    console.log 'inline scenario 5: you were on WL(s), but now you are removing WL(s) and adding BL(s)'


  # start building the modal
  modal_info_string =
    "<div class='wlbl-info-modal'><p>The following entry:</p> <span>#{dispute_url}</span>"

  # ADD TO LISTS INLINE
  if adjustment_type == 'add' || adjustment_type == 'replace'
    list_types = $(wlbl_form).find('.wlbl-entry-wlbl').text().trim().split(', ')
    endpoint = '/escalations/api/v1/escalations/webrep/disputes/bulk_wlbl_threatcat_adjust'
    data_new =
      adjustment_type: adjustment_type
      lists: new_lists_arr
      thrt_cat_ids: thrt_cat_ids
      note: curr_note

    if location.href.includes('webrep/disputes')
      console.log 'inline scenario 1'  #  index/show/bfrp add/replace: use new endpoint + one entry url
      data_new.dispute_entries = [ dispute_entry_id ]  # ADD/REPLACE ALWAYS NEEDS AN ENTRY-ID, NOT A URL this ends up down in the ajax call below
    else if location.href.includes('webrep/research')
      console.log 'inline scenario 2'  # BFRP add/replace using new endpoint + one entry id
      data_new.urls = [ dispute_url ]  # THIS MUST BE URLS/IP_URI, there is no entry.id on bfrp currently

    # used for the modal
    added_lists = []
    $.each new_lists_arr, (i, entry) ->
      if($.inArray(entry, old_lists_arr) == -1) then added_lists.push(entry)

    if new_lists_arr.length   # below shows on 'adding', 'replacing' deals with TC's, not lists
      modal_info_string += "<span>Has been #{modal_action} the following WBRS Lists: <p>#{added_lists.join(', ')}</p></span>"

  # REMOVE FROM LISTS INLINE
  else if adjustment_type = 'remove'
    console.log 'inline scenario 3' # index/show/bfrp page REMOVE: use old endpoint + one entry url'
    data_old =
      ip_uris: [dispute_url]
      list_types: removed_lists_arr
      note: curr_note   # ensure this is working
      thrt_cat_ids: thrt_cat_ids
    endpoint = '/escalations/api/v1/escalations/webrep/disputes/bulk_rule_ui_wlbl_remove'

    modal_info_string += "<span>Has been removed from the following WBRS Lists: <p>#{removed_lists_arr.join(', ')}</p></span>"


  # 1) ONE API CALL - NORMAL SCENARIOS
  if second_adjustment_type == false
    console.log 'SINGLE-API CALL SCENARIO BEGIN:'
    if adjustment_type == 'add' || adjustment_type == 'replace'   # add or replace
      data = data_new
      endpoint = '/escalations/api/v1/escalations/webrep/disputes/bulk_wlbl_threatcat_adjust'
    if adjustment_type == 'remove'
      data = data_old
      endpoint = '/escalations/api/v1/escalations/webrep/disputes/bulk_rule_ui_wlbl_remove'

    console.log endpoint
    console.log data

    std_msg_ajax(
      url: endpoint
      method: 'POST'
      data: data
      error_prefix: 'Error adjusting WL/BL information.'
      success_reload: true
      success: (response) ->

        if thrt_cat_ids.length
          modal_info_string += "<span>With the following threat categories updated: <p>#{thrt_cat_names.join(', ')}</p></span>"

        modal_info_string += "</div>"  # finish the modal

        std_msg_success("Entry has been updated", [modal_info_string])
      error: (response) ->
        std_api_error(response, 'Error updating this entry')
      completed: () ->
        $('.dispute-wlbl-adjust-wrapper .dropdown-submit-button').html('Submit Changes')
    )

  # 2) TWO API CALLS - RARE SCENARIOS (add and remove same time)
  else if second_adjustment_type = true
    console.log 'DOUBLE-API CALL SCENARIO BEGIN:'

    # FIRST API CALL
    console.log 'FIRST API CALL STARTS HERE'
    console.log '/escalations/api/v1/escalations/webrep/disputes/bulk_wlbl_threatcat_adjust'
    console.log data_new

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/bulk_wlbl_threatcat_adjust'
      method: 'POST'
      data: data_new
      error_prefix: 'Error adjusting WL/BL information.'
      success_reload: false
      success: (response) ->
        console.log 'FIRST API SUCCESS. \nSECOND API CALL STARTS HERE:'
        console.log '/escalations/api/v1/escalations/webrep/disputes/bulk_rule_ui_wlbl_remove'

        data_old =
          ip_uris: [dispute_url]
          list_types: removed_lists_arr
          note: curr_note
          thrt_cat_ids: thrt_cat_ids

        console.log data_old


        # SECOND API CALL
        std_msg_ajax(
          url: '/escalations/api/v1/escalations/webrep/disputes/bulk_rule_ui_wlbl_remove'
          method: 'POST'
          data: data_old
          error_prefix: 'Error adjusting WL/BL information.'
          success_reload: true
          success: (response) ->
            console.log 'SECOND API SUCCESS: SECOND CALL HAS PASSED'  # only show the modal_info_string after 2nd api completes

            modal_info_string += "<span>Has also been removed from the following WBRS Lists: <p>#{removed_lists_arr.join(', ')}</p></span>"
            if thrt_cat_ids.length
              modal_info_string += "<span>With the following threat categories updated: <p>#{thrt_cat_names.join(', ')}</p></span>"

            modal_info_string += "</div>"  # finish the modal

            std_msg_success("Entry has been updated", [modal_info_string])
          error: (response) ->
            std_api_error(response, 'Error updating this entry')
          completed: () ->
            $('.dispute-wlbl-adjust-wrapper .dropdown-submit-button').html('Submit Changes')
        )

      error: (response) ->
        std_api_error(response, 'Error updating this entry')
    )

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
          console.log response
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
    current_lists = "<span class='missing-data'>Not on a list</span>"
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
  curr_cbs = ''

  # Grab original 'current' lists
  current_lists = $($(dropdown).find('.wlbl-entry-wlbl')[0]).text()
  list = current_lists.split(', ')

  # If current entry isn't on a list, all toggles should be 'off'
  if current_lists == "Not on a list"
    current_lists = "<span class='missing-data'>Not on a list</span>"
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

  # Clean slate the WL/BL checkboxes
  $(dropdown).find(".wl-bl-list-inline:checkbox")
    .prop('disabled', false).closest('li').removeClass('grayed-out')

  # Restore the disabled/enabled states of the list cb's for inline
  unless current_lists.includes('WL-') and current_lists.includes('BL-')  # edge case
    if current_lists.includes('WL-') then curr_cbs = 'BL-'
    else if current_lists.includes('BL-') then curr_cbs = 'WL-'

    $(dropdown).find(".wl-bl-list-inline:checkbox[value^='#{curr_cbs}']")
      .prop('disabled', true).closest('li').addClass('grayed-out')

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
    $(dropdown).find('.threat-cat-row').removeClass('hidden')
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
  list_cells = $('#index-adjust-wlbl, #wlbl_entries_button')
    .next('.dropdown-menu').find('.lists-row li')
  tc_cells = $('.dispute-wlbl-adjust-wrapper .threat-cat-cell')

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
    $('.dispute-wlbl-adjust-wrapper .dropdown-submit-button').html('Submit Changes')

  # bulk bfrp CLICK INPUT: add id's to this cb (on page) to bfrp bulk (in dropdown) for tests
  $('.bfrp-table .dispute_check_box').click ->
    $('.bfrp-table .dispute_check_box').each (i) ->
      $(this).attr('class','')   # clean slate the cbs to default first on each click
      $(this).addClass("dispute_check_box")
      $(this).addClass("bfrp-checkbox-#{i}")
#
    $('.bfrp-table .dispute_check_box:checked').each (i) ->
      $(this).addClass("bfrp-result-no-#{i}")    # then for checked, add class for testing, for the on-page checkboxes

  # wl/bl dropdowns, click a wl/bl list cell or tc cell and it will toggle the adjacent cb
  $.merge(list_cells, tc_cells).click (e) ->
    unless e.target.nodeName.toLowerCase() == 'input'
      $(this).find('input:checkbox').click()

  # submit button clicked inside wl/bl dropdown, add mini loader
  $('.dispute-wlbl-adjust-wrapper .dropdown-submit-button').click ->
    $(this).html('Processing...<span class="mini-loader loader-white"></span>').prop('disabled', true)

  # research rows: on page load, verify we're on research tab or bfrp
  if $('#research-tab').length || $('.reputation-research-search-wrapper').length
    $('.research-table-row').each ->
      ip_uri = $(this).find('.entry-data-content').text().trim()
      tc_area = $(this).find('.wlbl-tc-research-span')

      # sort the curr wl/bl lists by weak to heavy
      lists_orig = $(this).find('.wlbl-table-result').text().trim()
      lists_sort = lists_orig.split(', ').sort().reverse().join(', ')
      $(this).find('.wlbl-table-result').html(lists_sort)

      # threat category(s) - uses a separate API call - needs to be handled w/ a js promise (1-2 sec lag)
      tc_promise = new Promise (resolve, reject) ->
        tc_json = get_threat_categories(ip_uri)  # this is the actual api call
        if tc_json then resolve tc_json

      tc_promise.then (result) ->
        {threat_categories} = JSON.parse(result)
        if threat_categories.length == 0 then tc_str = '<span class="threat-cat-no-data">No category</span>'
        else tc_str = threat_categories.join(', ')

        tc_area.html(tc_str)  # place the TC's in the html

  # after a click inside a wl/bl dropdown, lets handle wl/bl + tc validation for bulk or inline adjust wl/bl
  $('.dispute-wlbl-adjust-wrapper input').click ->
    cb_value = $(this).attr('value')

    if $(this).prop('class').length
      cb_class = $(this).prop('class').split(' ')[0]
    else cb_class = ''

    dropdown_id = '#' + $(this).closest('.dropdown-menu').attr('id')  # get the dropdown id for the input just clicked

    # Dropdown for adjust wl/bl, add some shortcuts for all these vars
    $(dropdown_id).ready ->
      lists_row = $(this).find('.lists-row')
      old_lists = $(this).find('.wlbl-entry-wlbl').text().trim()
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
      disable_submit = $(this).attr('data-disable-submit')

      enableSubmit = () -> $(submit_button).prop('disabled', false)
      disableSubmit = () -> $(submit_button).prop('disabled', true)

      clearAllInputs = () ->
        $(wlbl_dropdowns).find('input:checkbox').prop('checked', false)
        $(wlbl_dropdowns).find('.tc-replace-note').addClass('hidden')
        disableSubmit()

      # show/hide the the threat category row in dropdowns on BL cb click
      if cb_value.includes('BL-') and bl_num > 0
        unless $(dropdown_id).find('#wlbl-remove').prop('checked')
          tc_row.removeClass('hidden')

      if cb_value.includes('BL-') and bl_num == 0
        tc_row.addClass('hidden')

      # change this to else if, if restore above
      if cb_value.includes('BL-') and bl_num == 0 and add_radio.prop('checked')
        $(dropdown_id).find('.threat-cat-row input').prop('checked', false)


      # ensure user doesnt accidentally select both wl's and bl's at same time, don't bother if curr lists has wl's and bl's
      # if user selects a BL cb, gray out and disable the WL cb's, for example
      unless old_lists.includes('WL-') and old_lists.includes('BL-')
        if wl_num > 0 || bl_num > 0
          if wl_num > 0 then curr_cbs = 'BL-'
          if bl_num > 0 then curr_cbs = 'WL-'
          $(dropdown_id).find(":checkbox[value^='#{curr_cbs}']").prop('disabled',true).closest('li').addClass('grayed-out')

        else if wl_num == 0 || bl_num == 0
          if wl_num == 0 then curr_cbs = 'BL-'
          if bl_num == 0 then curr_cbs = 'WL-'
          $(dropdown_id).find(":checkbox[value^='#{curr_cbs}']").prop('disabled',false).closest('li').removeClass('grayed-out')

        # BULK SPECIFIC
        # clean slate the disabled states for wl/bl cb's, at-a-time validation
        if (wl_num == 0 && bl_num == 0) || (wl_num > 0 && bl_num > 0)
          $(dropdown_id).find(":checkbox").prop('disabled',false).closest('li').removeClass('grayed-out')

      # Add / Remove - clean slate on click, .merge() allows selecting mult vars in jquery
      $.merge(add_radio, remove_radio).click ->
        lists_row.removeClass('hidden')
        $.merge(tc_row, tc_note_replace).addClass('hidden')
        clearAllInputs()


      replace_radio.click ->
        tc_text_array = $('.wlbl-threat-cat').text().trim().split(', ')  # tc_text_array is array of 'Bogon','Botnets', etc
        tc_cell_array = $(dropdown_id).find('.threat-cat-cell').toArray()
        $.merge(lists_row, tc_note_max).addClass('hidden')
        $.merge(tc_row, tc_note_replace).removeClass('hidden')
        $(dropdown_id).find('.dispute-wlbl-adjust-wrapper input:checkbox').prop('checked', false)

        disableSubmit()

        # get a filtered array of tc's to pre-toggle the checkboxes, entry is an html element w/ label + input
        tc_toggle_array = tc_cell_array.filter (entry) ->
          entry_matches = false
          $(tc_text_array).each (i, value) ->
            if value == $(entry).text().trim() then entry_matches = true
          if entry_matches then return entry

        $(tc_toggle_array).each -> $(this).find('input:checkbox').prop('checked', true)

      # tc note show/hide about 5 tc's max
      if add_radio.prop('checked') then tc_note_max.removeClass('hidden')
      else tc_note_max.addClass('hidden')

      # if change is checked and no tc's, then no bl's should be checked, ensure this
      if replace_radio.prop('checked') and tc_num == 0
        $(this).find('.lists-row input[value^="BL-"]').prop('checked', false)

      # this is the class for tc cb's
      if cb_class.includes('wlbl_thrt_cat_id')
        if replace_radio.prop('checked') and tc_num == 0
          tc_note_replace.removeClass('hidden')
        if tc_num > 5
          $(this).find('.five-note').addClass('required-bold')
        else if tc_num <= 5 and tc_num > 0
          $(this).find('.five-note').removeClass('required-bold')

      # every input click, disable submit unless certain criteria is met
      disableSubmit()

      # scenarios to enable the submit button
      conditionsArray = [
        wl_num > 0 && bl_num == 0 && tc_num == 0,
        bl_num > 0 && tc_num > 0 && tc_num <= 5,
        wl_num == 0 && bl_num == 0 && $(dropdown_id).find('.toggle-slider').length > 0,  # inline: de-toggle all wl/bl's? allow submit
        add_radio.prop('checked') && bl_num > 0 && tc_num > 0 && tc_num <= 5,
        remove_radio.prop('checked') && bl_num > 0,
        replace_radio.prop('checked') && bl_num == 0 && tc_num == 0,  # no tc's? no bl's either then, let them submit
        replace_radio.prop('checked') && tc_num > 0 && tc_num <= 5  # user can change existing tc's
      ]

      # if they pass everything else, allow Submit to proceed
      if conditionsArray.indexOf(true) >= 0 && $(dropdown_id).attr('data-disable-submit') != 'disable'
        enableSubmit()


# on page load, add the wl/bl + tc input event listeners inside the dropdowns
$ ->
  add_wlbl_threat_cat_listeners()
