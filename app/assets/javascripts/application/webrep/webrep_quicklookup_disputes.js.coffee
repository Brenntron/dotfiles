$ ->
  headers =  'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val()

  ongoing_detail_search = false
  ongoing_quick_search = false
  current_search_count = 0
  completed_counter = 0
  window.isEmpty = (item) ->
    ####
    # function to check whether or not objects and strings are empty, more variable types can be added as needed
    ####
    type = typeof item
    switch(type)
      when 'object'
        return !Object.keys(item).length
      when 'string'
        return /^\s*$/.test(item)

  window.stringIncludes = (str, substring) ->
    return str.indexOf(substring) != -1

  #counter for ajax calls
  $(document).bind(
    ajaxComplete: () ->

      ####
      # selected_rows needs to be multiplied by the number of ajax calls that are being made to
      # accurately gauge the number of calls
      # This controls the show/hide of the loading wheel depending on if all ajax calls for quicklookup have been completed.
      ####

      selected_rows = current_search_count * 5
      if ongoing_quick_search
        completed_counter++
        if completed_counter == selected_rows && ongoing_quick_search
          ongoing_quick_search = false
          completed_counter = 0
          $('#quick-lookup-loader').removeClass('visible-ajax-message')
          $('#quick-lookup-loader').css('display', 'none')
  )


  $(document).ready ->
    update_tabs( window.location.hash )

  $('#research-tabs li').on 'click', ->
    update_tabs( window.location.hash )

  window.update_tabs = ( location ) ->
#    just making sure that correct loader is hidden/shown
#    having one and changing location has been less buggy/complicated than having 2 separate ones
    if location == '#lookup-quick'
      $('.lookup-detail').css('display', 'none')
      $('#detail-lookup-loader').removeClass('visible-ajax-message')
      $('#detail-lookup-loader').css('display',' none')
      if !ongoing_quick_search
        $('#quick-lookup-loader').removeClass('visible-ajax-message')
      else
        $('#quick-lookup-loader').addClass('visible-ajax-message')
      window.history.pushState("", "", '/escalations/webrep/research#lookup-quick');
    else if location == '#lookup-detail' || location == ''
      $('#quick-lookup-loader').removeClass('visible-ajax-message')
      if !ongoing_detail_search
        $('#detail-lookup-loader').removeClass('visible-ajax-message')
        $('.lookup-detail').css('display', 'unset')
      else
        $('#detail-lookup-loader').addClass('visible-ajax-message')
        $('.research_results').css('display', 'none')

  window.isEmpty = (item) ->
    ####
    # function to check whether or not objects and strings are empty, more variable types can be added as needed
    ####
    type = typeof item
    switch(type)
      when 'object'
        return !Object.keys(item).length
      when 'string'
        return /^\s*$/.test(item)

  window.close_modal = () ->
    $('#confirmation-modal').modal('toggle')

  window.detail_search = () ->
    ongoing_detail_search = true
    text_list = $('#search_uri').val().split(/[\s\t\n]+/).filter((el)=> return el != "" )
    if text_list.length == 0
      std_msg_error('Error Submitting Search',["Please enter at least one URL or IP address."], reload: false)
    else
      $('#detail-lookup-loader').addClass('visible-ajax-message')
      $('.lookup-detail, .research_results').css('display', 'none')
      check_ips(text_list).then( (response)=>
        { data } = response
        valid_list = []
        url_list = []
        invalid_list = []
        for name, value of data
          if !value
            url_list.push(name)
          else
            valid_list.push(name)
        if url_list.length == 0
          $('#detail-lookup-loader').addClass('visible-ajax-message')
          $("#research_form").submit()
        else
          $.ajax(
            url: '/escalations/api/v1/escalations/webrep/disputes/is_valid_url'
            method: 'GET'
            headers: headers
            data: {'uri': url_list}
            dataType: 'json'
            success: (response) ->
              {data} = response
              for name, value of data
                if value
                  valid_list.push(name)
                else
                  invalid_list.push(name)
              if valid_list.length == 0
                std_msg_error('Error Submitting Search',["Please enter at least one valid URL or IP address."], reload: false)
              else
                submit_list = valid_list.join('\n')
                $("#search_uri").val(submit_list)
                $('#detail-lookup-loader').addClass('visible-ajax-message')
                $("#research_form").submit()

                for el, i  in valid_list
                  valid_list[i] = "<span class='col-tag'>#{el}</span>"
                for el, i in invalid_list
                  invalid_list[i] = "<span class='col-tag'>#{el}</span>"
                if invalid_list.length > 0
                  std_msg_success('Submitting Search',["<div class='submit-search-msg'>The following URLs and IPs are being submitted: #{valid_list.join()}</div> <div class='submit-search-msg'>The following URLs and IPs are invalid: #{invalid_list.join()} </div>"], reload: false)

          )
      )


  window.reset_error_modal = () ->
    $( '#error_modal' ).dialog(
      position:
        my: "right",
        at: "top+15%",
        of: window
    )
    $( '#error_modal .modal-body' ).empty()
    $( '#error_modal' ).dialog( 'destroy' )

  window.open_adjust_reptool = () ->
    dropdown = $('#reptool_entries_bl_dropdown')
    list = $(dropdown).find('ul')
    type = 'reptool'

    reptool_options = [ "attackers", "bogon", "bots", "cnc", "cryptomining",
      "dga", "exploitkit", "malware", "open_proxy", "open_relay",
      "phishing", "response", "spam", "suspicious", "tor_exit_node"]

    if !$(list).has('label').length
      build_checkbox_list(reptool_options, list, type)

  window.open_wlbl = () ->
    list = $('#wlbl_entries_dropdown').find('ul')
    type = 'wlbl'
    wlbl_options = [ "WL-weak", "WL-med", "WL-heavy", "BL-weak", "BL-med", "BL-heavy"]

    if !$(list).has('label').length
      build_checkbox_list(wlbl_options, list, type)

  window.select_all_detailed = (check)->
    is_checked = $(check).prop('checked')
    $('.dispute_check_box').prop('checked', is_checked)
    if $('.dispute_check_box:checked').length > 0
      $('#add-to-ticket-button').removeAttr('disabled')
    else
      $('#add-to-ticket-button').prop('disabled', 'disabled')

  $(document).on 'click', '.dispute_check_box', () ->
    if $('.dispute_check_box').not(':checked').length > 0
      $('#select-all-entries').prop('checked', false)
    else
      $('#select-all-entries').prop('checked', true)

    if $('.dispute_check_box:checked').length > 0
      $('#add-to-ticket-button').removeAttr('disabled')
    else
      $('#add-to-ticket-button').prop('disabled', 'disabled')

  window.build_checkbox_list = (arr, list, type) ->
    ####
    # the checkbox list for the dropdown is built here when the dropdown is first opened
    # because I don't want to type the same html element over and over + easier if drop in more vals without having to change it in multiple places
    ####
    for opt in arr
      checkbox =
        "<li> <label>
          <input name='#{opt}' id='#{opt}' value='#{opt}' type='checkbox' class='adjust_#{type}_checkbox'/>#{opt}
        </label> </li>"
      $(list).append(checkbox)

  window.col_tag_format = (array) ->
    ####
    # like it says on the tin, formatting the initial col-tags for the action column
    ####
    if typeof array == 'string'
      array = array.split(',')
    check_list_array = []
    check_list = ''
    for val in array
      check_name = "<span data='#{val}' class='col-tag'>#{val}</span>"
      check_list_array.push(check_name)
    if check_list_array.length == 2
      check_list = check_list_array.join(' and ')
    else
      check_list = check_list_array.join(', ').replace(/, ([^,]*)$/, ', and $1')
    return check_list

  $(document).on 'click', '#clear-all-actions', (e) ->
    ####
    # clears all actions from every selected row
    ####
    e.preventDefault()
    $('#submit-rep-changes').attr('disabled', true)
    selected_rows = $('.col-select-all input:checked')
    $( selected_rows ).each ()->
      row = $( this ).closest('tr')
      $( row ).find('.col-actions').empty()
      $( row ).find('.col-clear-actions').empty()

  $('.wlbl_thrt_cat_id').on 'click', ->
    ####
    #Only allow 5 threat cat ids to be selected
    ####
    checked = $('.wlbl_thrt_cat_id:checked').length
    submit_btn = $('#wlbl_entries_dropdown .dropdown-submit-button')
    if checked > 0 && checked < 6
      $(submit_btn).removeAttr('disabled')
      $('.five-note').removeClass('required-bold')
    else
      $(submit_btn).attr('disabled', true)
      if checked > 5
        $('.five-note').addClass('required-bold')

  $(document).on 'click', '.row-action-clear', (e) ->
    ####
    #This removes all actions from a single row
    ####
    e.preventDefault()
    { target } = e
    row = $(target).closest('tr')
    col_actions = row.find('.col-actions')
    $(target).remove()
    $( col_actions ).empty()
    submit_rep_check()


  $(document).on 'click', '.col-actions .col-tag', () ->
    ####
    # handles deleting individual actions from an action column and reformatting the div it lives in + updating the data attribute of the action <p>
    ####
    action = this.getAttribute("data");
    action_p = $(this).parents('p')[0]
    action_edit = $(action_p).text().split(':')[0]
    row = $(this).parents('tr')[0]
    col_clear = $(row).find('.col-clear-actions')[0]
    action_col = $(row).find('.row-action-clear')[0]
    if action_p.getAttribute("wlbl_data") != undefined
      data_type = "wlbl_data"
    else
      data_type = "data"

    # original data
    data = action_p.getAttribute(data_type).split(',')
    # newly refined data with shit removed
    data = data.filter((data_actions) -> action != data_actions )

    $(this).remove()
    action_p.setAttribute(data_type, data)
    if data.length == 0
      if $(action_p).hasClass('wlbl-action-col')
        $(row).find('.threat-cat-col').remove()
      if $(action_p).hasClass('threat-cat-col')
        $(row).find('.wlbl-action-col').remove()
      $(action_p).remove()
      if $(action_col).html() == ''
        $(col_clear).find('button').click()
    else
      unless $.trim(action_edit) == 'Threat Categories'
        col_dialog = "#{action_edit}: #{col_tag_format(data)}"
        $(action_p).html(col_dialog)


  $(document).on 'change', '#select-all-bulk', (e) ->
    ####
    # handles selection of all checkboxes in quicklookup table
    ####
    e_val = e.currentTarget.checked
    select_cols = $('.col-select-all input')
    for col in select_cols
      # We need to set both attr and prop here.
      # prop makes sure all values actually get changed,
      # attr makes sure that values persist after rows have been added
      $(col).attr('checked', e_val)
      $(col).prop('checked', e_val)
      if e_val == false
        $(col).removeAttr('checked')
    get_rep_check()

  $(document).on 'change', '.col-select-all input', (e) ->
    ####
    # handles selection of single checkboxes in quicklookup table
    ####
    select_cols = $('.col-select-all input')
    select_vals = []
    val = $(this).prop('checked')
    if !val
      $(this).removeAttr('checked')
    else
      $(this).attr('checked', 'true')
    for col in select_cols
      select_vals.push( $(col).prop('checked') )
    bulk_value = select_vals.every( (col) -> return col)
    $('#select-all-bulk').prop('checked', bulk_value)
    get_rep_check()

  $(document).on 'change', '.adjust_reptool_checkbox, .status_bl', () ->
    ####
    # depending on what radio button is selected, the available actions in the reptool dropdown will change
    ####
    submit_btn = $('#reptool_entries_bl_dropdown .dropdown-submit-button')
    class_bl = $('.status_bl:checked').val().replace('reptool-', '')

    switch (class_bl)
      when 'maintain'
        $('#reptool_entries_bl_dropdown .reptool-class-radio-row').show()
        $('#reptool_entries_bl_dropdown .reptool-classifications-row').show()
      when 'override'
        $('#reptool_entries_bl_dropdown .reptool-class-radio-row').hide()
        $('#reptool_entries_bl_dropdown .reptool-classifications-row').show()
      when 'drop'
        $('#reptool_entries_bl_dropdown .reptool-classifications-row').hide()

    if $('.adjust_reptool_checkbox:checked').length || class_bl == 'drop'
      submit_btn.prop('disabled', false)
    else
      submit_btn.prop('disabled', true)

  bl_array = ['BL-weak', 'BL-med', 'BL-heavy']
  wl_array = ['WL-weak', 'WL-med', 'WL-heavy']

  $(document).on 'change', '.adjust_wlbl_checkbox', '.wlbl-radio-add', () ->
    submit_btn = document.querySelector('#wlbl_entries_dropdown .dropdown-submit-button')
    all_checked_items = $('.adjust_wlbl_checkbox:checked')
    add_wlbl = $('#wlbl-quick-add').is(":checked")

    tc_row = document.querySelector('#wlbl_entries_dropdown .threat-cat-row')
    disabled = true
    bl_hide = true
    wl_check = false
    for check in all_checked_items
      val = $(check).val()
      if bl_array.indexOf(val) > -1 then bl_hide = false
      if wl_array.indexOf(val) > -1 then wl_check = true

    for bl in bl_array
      bl_el = $("[name=#{bl}]")
      bl_el.prop('disabled', wl_check )
      if wl_check
        $(bl_el.closest('li')).addClass('grayed-out')
      else
        $(bl_el.closest('li')).removeClass('grayed-out')

    for wl in wl_array
      wl_el = $("[name=#{wl}]")
      wl_el.prop('disabled', !bl_hide )
      checked = $('.wlbl_thrt_cat_id:checked').length
      if !bl_hide
        $(wl_el.closest('li')).addClass('grayed-out')
        if add_wlbl
          if checked > 0 && checked < 6
            disabled = false
        else
          disabled = false
      else
        $(wl_el.closest('li')).removeClass('grayed-out')

    if wl_check
      disabled = false

    if !bl_hide && add_wlbl
      $(tc_row).removeClass('hidden')
    else
      $(tc_row).addClass('hidden')

    $(submit_btn).prop('disabled', disabled)

  $('.wlbl-radio-add').click ->
    toggle_tc_visibility(this)

  window.toggle_tc_visibility = (radio) ->
    action  = $(radio).val()
    wrapper = $(radio).parents('.dropdown-menu')[0]
    tc_row  = $(wrapper).find('.threat-cat-row')[0]

    if action == 'remove'
      $(tc_row).addClass('hidden')
      $('.wlbl_thrt_cat_id').each ->
        $(this).prop('checked', false)
    else
      $(tc_row).removeClass('hidden')

  window.call_action_switchboard = (disputes) ->
    $('#confirmation-modal').modal('hide')
    ####
    # data is set and each action calls the appropriate endpoint here
    ####
    comment = $('#confirmation-modal').find('.comment-input').text()
    error_array = []

    ajax_count = Object.keys(disputes).length - 1
    dispute_calls = setInterval(()->

      if ajax_count == 0
         # Once all Disputes have been processed, pass list of disputes and error array to the bulk quick update
         clearInterval(dispute_calls)
         quick_bulk_update(disputes, error_array)
    , 200);

    for dispute, value of disputes
      dispute = dispute.trim()
      { action } = value
      if action != undefined
        for act in action
          for key, value of act
            switch key
              when 'maintain'
                classifications = Array.from(new Set(act[key]))
                data = [{
                  'action': 'ACTIVE'
                  'entries': [dispute]
                  'classifications': classifications
                  'comment': comment
                }]

                maintain_reptool_bl(data).then( (response)=>
                  ajax_count--
                  if !response
                    error_message = "<p>Unable to update all reptool entries.</p>"
                    error_array.push(error_message)
                )

              when 'override'
                classifications = Array.from(new Set(act[key]))
                data = [{
                  'action': 'ACTIVE'
                  'entries': [dispute]
                  'classifications': classifications
                  'comment': comment
                }]

                maintain_reptool_bl(data).then((response)=>
                  ajax_count--
                  if !response
                    error_message = "<p>Unable to update all reptool entries.</p>"
                    error_array.push(error_message)
                )
              when 'drop'
                data = {
                  'action': 'EXPIRED'
                  'entries': [dispute]
                  'comment':  comment
                  'classifications': act[key]
                }
                drop_reptool_bl(data).then((response)=>
                  ajax_count--
                  if !response
                    error_message = "<p>Unable to drop all reptool entries.</p>"
                    error_array.push(error_message)
                )
              when 'add'

                data = {
                  'urls':[dispute]
                  'trgt_list': act[key]
                  'note': comment
                }

                if stringIncludes(act[key][0], 'BL')
                  for el in action
                    #####
                    # set the values of threat_cat ids if the BL is being set
                    #####
                    if el.tc_ids
                      data.thrt_cat_ids = el.tc_ids

                adjust_wlbl(data).then((response) =>
                  ajax_count--
                  if !response
                    error_message = "<p>Unable to adjust all wlbl entries.</p>"
                    error_array.push(error_message)
                )

              when 'remove'
                data = {
                  'ip_uris': [dispute]
                  'list_types': act[key]
                  'note': comment
                }
                remove_wlbl(data).then((response)=>
                  ajax_count--
                  if !response
                    error_message = "<p>Unable to remove all wlbl entries.</p>"
                    error_array.push(error_message)
                )


  window.maintain_reptool_bl = (data)->
    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webrep/disputes/maintain_reptool_bl'
      headers: headers
      data:
        data: data
      success_reload:false
      success: () ->
        $('#confirmation-modal').modal('hide')
    )

  window.drop_reptool_bl = (data) ->
    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webrep/disputes/drop_reptool_bl'
      headers: headers
      data: data
      success_reload:false
      success: () ->
        $('#confirmation-modal').modal('hide')
    )

  window.adjust_wlbl = (data) ->
    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webrep/disputes/uri_wlbl'
      headers: headers
      data: data
      success_reload:false
      success: () ->
        $('#confirmation-modal').modal('hide')
    )

  window.remove_wlbl = (data) ->
    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webrep/disputes/bulk_rule_ui_wlbl_remove'
      headers: headers
      data: data
      success_reload:false
      success: () ->
        $('#confirmation-modal').modal('hide')
    )

  window.check_actions = (action_classes) =>
    # depending on classlists, return appropriate action to take for final data for ajax call

    if stringIncludes(action_classes, 'reptool')

      if stringIncludes(action_classes, 'maintain')
        return 'maintain'
      else if stringIncludes(action_classes, 'override')
        return 'override'
      else if stringIncludes(action_classes, 'drop')
        return 'drop'

    else

      if stringIncludes(action_classes, 'add')
        return 'add'
      else if stringIncludes(action_classes, 'remove')
        return 'remove'
      else
        return 'tc_ids'

  window.quick_bulk_update = (data, errors) ->
      ####
      # super simple endpoint to quick look up bulk submit-thus sayeth chris
      # on success of at least some data, make disputes, otherwise display error message
      ####
    errors = Array.from(new Set(errors))
    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webrep/disputes/quick_bulk_update'
      data: update_data: data
      success_reload:false
      error_prefix: 'Error logging in.'
      success: (response) ->
        submitted_entries = []
        $('#quick-lookup-loader').removeClass('visible-ajax-message')
        if response
          for key, val of data
            if key != 'comment'
              submitted_entries.push(key.trim())
              el = document.querySelectorAll("td[data='#{key.trim()}']")
              $(el).closest('tr').remove()
          if  errors.length == 0
            std_msg_success('All Disputes were successfully created', ["Disputes were successfully created for the following entries:<div>#{submitted_entries.join(', ')}</div>"], reload: false)
          else
            submitted_msg = ''
            if submitted_entries.length > 0
              submitted_msg = "<div>Successfully created entries: #{submitted_entries.join(', ')}</div>"
              errors = "<div>Error creating the following entries: #{submitted_entries.join(', ')}</div>"
            std_msg_error('Error Creating disputes',[errors + submitted_msg], reload: false)
        return response
    )

  window.confirm_rep_changes = () ->

    ####
    #  confirm actions to be taken, data is prepared and  final submission of disputes to be made
    ####
    confirmation_rows = document.querySelector('#confirmation-modal tbody').rows
    $('#confirmation-modal').modal('toggle');
    $('#quick-lookup-loader').addClass('visible-ajax-message')
    disputes = { comment: $('.confirm-rep-input').text() }

    $( confirmation_rows ).each ->
        action_list = []
        cells = $(this).find('td')
        dispute = $( cells[0] ).text()
        actions = $( cells[1] ).children()

        for action, i in actions
          action_tags = []
          class_list = $(action).attr('class')

          if stringIncludes(class_list, 'reptool') && !stringIncludes(class_list, 'drop')
            action_tags = $(action).attr('reptool_classes').split(',')
          if stringIncludes(class_list, 'wlbl')
            action_tags = $(action).attr('wlbl_data').split(',')
          if stringIncludes(class_list, 'threat-cat-col')
            action_tags = $(action).attr('data').split(',').map((x) -> return parseInt(x) )

          formatted_action = check_actions(class_list)
          action_list.push( "#{formatted_action}": action_tags )

        actions = action: action_list
        disputes[dispute] = actions
        dispute_check = true

        for key, value of disputes
          if key != 'comment'
            if typeof value != 'object'
              dispute_check = false
              break

        if dispute_check
          call_action_switchboard(disputes)


  window.set_action_wlbl_col = () ->
    $(".dropdown.open").removeClass("open");
    $('.grayed-out').removeClass('grayed-out')
    reset_error_modal()

    error_array = []
    threat_cats_el = []
    threat_cats = []

    action_desc = 'Add to: '
    checked_bl = $('.adjust_wlbl_checkbox:checked').map( () -> return $(this).val() ).get()
    bl_check = checked_bl[0].indexOf('BL') != -1
    selected_rows = $('.col-select-all input:checked')
    list_action = $('.wlbl-radio-add:checked').val()

    if list_action == 'remove'
      action_desc = 'Remove from: '

    if bl_check
      # if bl is checked, format threat cats for the dispute
      checked_tc = $('.wlbl_thrt_cat_id:checked')
      for check in checked_tc
        val = $(check).val()
        label = $(check).next('label').html()
        threat_cats.push("#{val}")
        threat_cats_el.push("<span data='#{val}' class='col-tag threat-cat-tag'>#{label}</span>")

    selected_rows.each ()->
      wlbl_err = []
      tc_err = ''

      row = $(this).closest('tr')
      $(row).find('.wlbl-action-col').remove()
      $(row).find('.threat-cat-col').remove()
      selected_rows = $('.col-select-all input:checked')
      data = row.find('.col-bulk-dispute').text()

      if !isEmpty(data)
        error_message = "#{data}| "
        action_col = row.find('.col-actions')
        existing_p = ".#{list_action}  .wlbl-action-col"
        clear_col = row.find('.col-clear-actions')
        wlbl_col = row.find('.col-wlbl').text().replace(/ /g, '').split(',')
        tc_col = row.find('.col-threat-cats .rule-api-tc').text().split(', ')

        check_list_array = checked_bl.filter( (wlbl)->
          switch(list_action)
            when 'add'
              if wlbl_col.includes(wlbl)
                wlbl_err.push( "<span class='col-tag dialog-tag'>  #{wlbl}</span>" )
              return !wlbl_col.includes(wlbl)
            when 'remove'
              if !wlbl_col.includes(wlbl)
                wlbl_err.push( "<span class='col-tag dialog-tag'>  #{wlbl}</span>" )
              return wlbl_col.includes(wlbl)
        )

        threat_id_array = []
        current_threat_cats = []

        for tc in threat_cats_el
          tc_name = $(tc)[0].innerText
          if tc_name != undefined
            tc_check = stringIncludes(tc_col, tc_name)
            if list_action == 'add' && tc_check
              tc_err += tc
              tc_id = $(tc)[0].getAttribute('data')
            else
              current_threat_cats.push(tc)
              threat_id_array.push(tc_id = $(tc)[0].getAttribute('data'))

        if wlbl_err.length > 0
          error_message += "<span class='error-tag'>WLBL : #{wlbl_err.join(', ')}</span>"
        if tc_err != ''
          error_message += "<span class='error-tag'> Threat Categories : #{tc_err}</span>"
        check_list = col_tag_format(check_list_array)

        if current_threat_cats.join().length > 0
           current_threat_cats = "<p data='#{threat_id_array}' class='threat-cat-col'>Threat Categories: #{current_threat_cats.join('')} </p>"
        else
          current_threat_cats = ''

        col_dialog = "<p class='wlbl-action-col #{list_action}' wlbl_data='#{check_list_array}'>#{action_desc}  #{check_list} #{current_threat_cats}<p>"
        delete_button = '<button class="clear-action-button row-action-clear"></button>'

        if error_message.endsWith('</span>')
          error_html = "<div>#{error_message}<div>"
          error_array.push(error_html)

        if check_list_array.length
          $(existing_p).remove()
          $(action_col).append(col_dialog)
          if !$(clear_col).has(".clear-action-button").length
            $(clear_col).append(delete_button)

    submit_rep_check()

    if error_array.length
      $( '#error_modal' ).dialog().position('top')
      $( '#error_modal .modal-header' ).html( "<h4>Cannot #{list_action} the following WLBL disputes <h4>" )
      $( '#error_modal .modal-body' ).append( error_array )

  window.submit_quick_lookup = () ->
    $('#confirmation-modal  tbody').empty()
    $('#confirmation-modal').modal()

    rows = $( '.col-select-all' ).closest('tr')
    confirmation_dialog = []

    $(rows).each ->
      new_data = $(this).find('.col-bulk-dispute').text()
      actions_col = $( this ).find('.col-actions')
      wlbl_actions = $( this ).find('.wlbl-action-col').attr('wlbl_data')
      existing_reptool = ''
      wlbl_list = ''

      if actions_col.attr('reptool_classes') != undefined
        existing_reptool = "reptool_classes= #{actions_col.attr('reptool_classes')}"
      if wlbl_actions != undefined
        wlbl_list = "wlbl_data = #{wlbl_actions}"
      if !isEmpty(new_data) && new_data != undefined
        actions_col = $( this ).find('.col-actions')
        children = actions_col.children()
        if children.length
          html = "<tr>
                    <td> #{new_data} </td>
                  <td>"
          for child in children
            classes = $(child).attr("class")
            if !isEmpty(classes) && classes != undefined
              threat_cat_data = ''
              if classes == 'threat-cat-col'
                threat_cat_data = "data='#{$(child).attr('data')}'"
              html += "<div #{existing_reptool} #{wlbl_list} #{threat_cat_data} class='#{classes} repuation-dispute-modal'>#{$(child).html()}</div>"
          html += '</td> </tr>'
          confirmation_dialog.push( html )

    $('#confirmation-modal tbody').append(confirmation_dialog)

  window.submit_rep_check = () ->
    selected_rows = $( '.col-select-all input:checked' )
    col_length = 0
    selected_rows.each () ->
      row = $(this).closest('tr')
      col_actions = row.find('.col-actions').children().length
      col_length = col_length + col_actions
    if col_length > 1
      $('#submit-rep-changes').attr('disabled', false)
    else
      $('#submit-rep-changes').attr('disabled', true)

  window.set_action_col = () ->
    #####
    # set and format action to be taken in each row's action column
    #####
    $(".dropdown.open").removeClass("open");
    reset_error_modal()

    check_vals = $( '.adjust_reptool_checkbox:checked' ).map( () -> return $(this).val() ).get()
    class_reptool = $( '.status_bl:checked' ).val().replace( 'reptool-' , '' )
    reptool_add = $( '.reptool-add:checked' ).val()
    reptool_class = reptool_add
    status_class = "reptool-#{class_reptool}-submission"
    check_list = ''
    error_array = []
    error_header = "<h4>Cannot #{reptool_add} the following Reptool Classification dispute<h4>"

    switch (class_reptool)
      when 'maintain'
        status_string = "#{reptool_add.charAt(0).toUpperCase()}#{reptool_add.slice(1)} classifications:"
      when 'override'
        status_string = 'Add classifications: '
      when 'drop'
        status_string = 'Drop all classifications (set entry to EXPIRED)'
        reptool_add = 'drop'
        reptool_class = 'drop'

    $('.col-select-all input:checked').each () ->
      row = $(this).closest('tr')
      rep_status = row.find('.rep-status').text()
      data = row.find('.col-bulk-dispute').text()
      action_col = row.find('.col-actions')
      existing_reptool = row.find('.col-reptool-class:not(.missing-data)')
      rep_list = []
      actions = $(this).closest('tr').find('.col-actions')
      existing_reptool.each () ->
        $(actions).children().each ->
          action_data = $(this).attr('data')
          if action_data
            rep_list = action_data.trim().split(',')

        rep_list = this.innerText.split(',')
        if (class_reptool == 'maintain' || class_reptool == 'drop') && existing_reptool.length && !isEmpty(data)
          reptools =  $(existing_reptool).text().split(/[\s,]+/)
          reptool_array = reptools.filter( (val) => return val != 'ACTIVE' && val != 'EXPIRED')
          reptool_classes = Array.from(new Set(reptool_array)).join(',')
          $(action_col).attr( 'reptool_classes', reptool_classes )
      error_message = "#{data} | "
      if !isEmpty(data)

        if reptool_add == 'drop'
          if existing_reptool.length
            row.find( '.reptool-action-col' ).empty()
          else
            error_message = data + ' has no classifications to drop.'
        else
          $( '.drop.reptool-action-col' ).remove()
          actions = row.find('.col-actions')

          if reptool_add.toLowerCase() == 'add'
            check_class = '.remove'
          else
            check_class = '.add'

        existing_actions = rep_list
        $(actions).find("#{check_class} .col-tag").each () -> existing_actions.push( this.innerText )

        if reptool_add.toLowerCase() == 'remove'
            check_list = check_vals.filter( (rep)->
              if existing_actions.indexOf(rep) == -1 && rep_status == "ACTIVE"
                  error_message += "<span class='col-tag dialog-tag'>#{rep} </span>, "
                  return false
              else
                return true
            )
            reptool_tags = $(action_col).attr( 'reptool_classes').split(',')
            action_tags = reptool_tags.filter( (val) => if check_list.indexOf(val) == -1  && val != 'ACTIVE' && val != 'EXPIRED' then return val )
            $(action_col).attr( 'reptool_classes', action_tags )

        else if reptool_add.toLowerCase() == 'add'
            check_list = check_vals.filter( (rep)->
              if existing_actions.indexOf(rep) > -1 && rep_status == "ACTIVE"
                  error_message += "<span class='col-tag dialog-tag'>#{rep} </span>, "
                  return false
              else
                return true
            )
            $(action_col).attr( 'reptool_classes', check_list.concat(existing_actions) )

        clear_col = $( row.find('.col-clear-actions') )
        existing_p = action_col.find(".#{reptool_class}.reptool-action-col")
        delete_button = '<button class="clear-action-button row-action-clear"></button>'
        if error_message.endsWith(', ')
          error_message = error_message.slice(0, error_message.length - 2);
          error_html = "<div>#{error_message}<div>"
          error_array.push(error_html)
        else if error_message.includes('has no classifications to drop')
          error_html = "<div>#{error_message}<div>"
          error_array.push(error_html)

        col_dialog = "<p class='#{reptool_class} #{status_class} reptool-action-col' data='#{check_list}'> #{status_string} #{col_tag_format(check_list)} <p>"
        drop_check = reptool_add  == 'drop' && existing_reptool.length
        if check_list.length || drop_check
          clear_col.show()
          $( existing_p ).remove()
          $( action_col ).append( col_dialog )
          if !clear_col.has(".clear-action-button").length
            clear_col.append(delete_button)

    submit_rep_check()
    if  error_array.length
      $( '#error_modal' ).dialog().position('top')
      $( '#error_modal .modal-header' ).html( error_header )
      $( '#error_modal .modal-body' ).append(error_array)

  window.get_rep_check = (e)->
    disabled = true
    $('tr .col-select-all input').each ->
      row =  $(this).closest('tr')
      checked = this.checked
      data = row.find('.col-bulk-dispute').text().trim()
      if data != "" && checked
        disabled = false
#      if e.type == 'focusout'
##        row.find('.col-bulk-dispute').attr('data', data)
#        if row.find('.col-bulk-dispute').is(':empty')
#          row.find('.col-bulk-dispute').attr('data', '')
    document.getElementById('get-rep-data').disabled = disabled

  window.get_rep_data = ()->
    ####
    # get reputation data for all rows
    # after getting data, display in the appropriate column
    ####
    ongoing_quick_search = true
    search_items = []
    rows = $('.research-table tbody tr')
    $('.col-bulk-dispute').each ( ) ->
      checkbox = $(this).prev().find('input')
      searched = $(this).attr('searched')
      if checkbox.length
        index = $(this).parent('tr').index();
        text = $(this).text()
        if !isEmpty(text) && checkbox[0].checked && searched == undefined
          search_items.push({'search_text':text, "row_index": index})

    current_search_count = search_items.length

    for i in [0...search_items.length]
      $('#quick-lookup-loader').addClass('visible-ajax-message')
      {search_text, row_index}= search_items[i]
      item = search_text
      row = rows[row_index]

      if !isEmpty(item)
        # for each search item, call a promise to get the data. If success, the first then runs, setting the data in the rows.
        # if it fails, the second runs, catching the error
        new get_reptool(item, headers)
          .then ( set_reptool.bind( null, item, row) )
          .then null, (err) -> console.log err
        new get_wlbl(item, headers)
          .then( set_wlbl.bind( null, item, row) )
          .then null, (err) -> console.log err
        new get_cat(item, headers)
          .then ( set_cat.bind( null, item, row) )
          .then null, (err) -> console.log err
        new get_sds_threat_cat(item, headers)
          .then ( set_sds_threat_cat.bind( null, item, row) )
          .then null, (err) -> console.log err
        new get_rule_threat_cat(item, headers)
          .then ( set_rule_threat_cat.bind( null, item, row) )
          .then null, (err) -> console.log err
        new get_wbrs(item, headers)
          .then( set_wbrs.bind( null, item, row) )
          .then null, (err) -> console.log err

  window.get_reptool = (item, headers) ->
    data = {'ip_uris':[item.trim()]}
    $.ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/bulk_reptool_get_info_for_form'
      method: 'POST'
      data: data
      headers: headers
      success: (response) -> return response
      error: (response) -> return response
    )

  window.get_wlbl = (item, headers) ->
    data = {'entry': item.trim()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/rule_ui_wlbl_get_info_for_form'
      method: 'GET'
      headers: headers
      data: data
      dataType: 'json'
      success: (response) -> return response
      error: (response) -> return response
    )

  window.get_wbrs = (item, headers) ->
    data = {'uri': item.trim()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/wbrs_info'
      method: 'GET'
      headers: headers
      data: data
      dataType: 'json'
      success: (response) -> return response
      error: (response) -> return response
    )

  window.get_cat = (item, headers) ->
    data = {'uri': item.trim()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaints/uri_cat_info'
      method: 'GET'
      headers: headers
      data: data
      dataType: 'json'
      success: (response) -> return response
      error: (response) -> return response
    )

  window.get_sds_threat_cat = (item, headers) ->
    data = {'uri': item.trim()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/threat_categories'
      method: 'POST'
      headers: headers
      data: data
      dataType: 'json'
      success: (response) -> return response
      error: (response) -> return response
    )

  window.get_rule_threat_cat = (item, headers) ->
    data = {'uri': item.trim()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/rule_api_info'
      method: 'GET'
      headers: headers
      data: data
      dataType: 'json'
      success: (response) -> return response
      error: (response) -> return response
    )

  window.set_reptool = ( item, row, data) ->
    { classification, status } = JSON.parse(data)[0]
    col_reptool = $(row).children('.col-reptool-class')

    if classification != 'No active classifications'
      new_reptool = classification.toString()
      col_reptool.html( new_reptool + " <span class='rep-status'>#{status}</span>")
    else
      col_reptool.html( 'Not on RepTool' )
      col_reptool.addClass('missing-data')

  window.set_wlbl = ( item, row, data) ->
    { data } = JSON.parse(data)
    col_wlbl = $(row).children('.col-wlbl')
    col_dispute = $(row).find('.col-bulk-dispute')
    if data.length
      text = data.join(', ')
    else
      text = "<span class='missing-data'>No Data</span>"
    col_wlbl.html( text )
    col_dispute[0].setAttribute('searched', true)
  window.set_cat = ( item, row, data) ->
    { data } = JSON.parse(data)
    cat_col = $(row).children('.col-category')

    if !isEmpty(data)
      categories = ''
      for key, value of data
        { descr } = value
        categories += "#{descr}, "
      categories = categories.substring(0, categories.length - 2)
      cat_col.text( categories )
    else
      cat_col.text('No data')
      cat_col.addClass('missing-data')

  window.set_rule_threat_cat = ( item, row, data) ->
    col_tc = $(row).children('.col-threat-cats')
    $(row).find('.rule-api-tc').remove()
    data = JSON.parse(data).data
    if data.length > 0 && data != undefined && data != ''
      data = data[ data.length - 1]
      { threat_cats } = data
      tc_array = threat_cats.map(( threat_cats ) => threat_cats.name);
      if tc_array.length
        text = "<span class='rule-api-tc'> #{tc_array.join(', ')}</span>"
      else
        text = '<span class="missing-data rule-api-tc"> No Rule API data</span>'
      col_tc.prepend(" #{text}")
    else
      col_tc.prepend( " <span class='missing-data rule-api-tc'> No Rule API data</span>" )

  window.set_sds_threat_cat = ( item, row, data) ->
    col_tc = $(row).children('.col-threat-cats')
    $(row).find('.tc_data').remove()
    { threat_categories } = JSON.parse(data)
    title = "It may take several hours for SDS threat category values to reflect changes."
    if threat_categories != undefined
      if threat_categories.length
        text = "<span class = 'tc_data esc-tooltipped' title= '#{title}'> |  #{threat_categories.join(', ')} </span>"
      else
        text = "<span class='missing-data tc_data esc-tooltipped' title= '#{title}'> | No SDS data</span>"
      col_tc.append( text )
    else
      col_tc.append( "<span class='missing-data tc_data esc-tooltipped' title='#{title}'> | No SDS data</span>")

  window.set_wbrs = ( item, row, data) ->
    { score, rulehits } = data.json.data
    col_wbrs = $(row).children('.col-wbrs')
    col_wbrs_rule = $(row).children('.col-wbrs-rules')
    col_wbrs_hits = $(row).children('.col-wbrs-rule-hits')

    col_wbrs_rule.text( rulehits.join(', ') )
    col_wbrs_hits.text( rulehits.length )

    if rulehits.length == 0
      col_wbrs_rule.text('No data')
      col_wbrs_rule.addClass('missing-data')

    else
      col_wbrs_rule.text( rulehits.join(', ') )
    if score != 'noscore'
      if  Number(score) == score && score % 1 == 0
        score = score.toFixed(1)
      col_wbrs.text( score )
    else
      col_wbrs.text( '0.0' )
