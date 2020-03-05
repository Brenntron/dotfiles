$ ->

  completed_counter = 0
  headers =  'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val()
  $(document).bind(
    ####
    #This controls the show/hide of the loading wheel depending on if all ajax calls have been completed.
    #There were issues with using ajaxStop, but this works
    ####
    ajaxStart: () ->
      $('.ajax-message-div').css('display', 'flex')
    ajaxStop: () ->
      $('.ajax-message-div').hide()
    ajaxComplete: () ->
      completed_counter++
      selected_rows = $('.col-select-all input:checked').length * 4 - 4
      if completed_counter == selected_rows
        $('.ajax-message-div').hide()
  )
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

  window.select_all_detailed = (check)->
    is_checked = $(check).prop('checked')
    $('.dispute_check_box').prop('checked', is_checked)
    if $('.dispute_check_box:checked').length > 0
      $('#add-to-ticket-button').removeAttr('disabled')
    else
      $('#add-to-ticket-button').prop('disabled', 'disabled')

  $(document).on 'click', '.dispute_check_box', (e) ->
    is_checked = $(e.target).prop('checked')
    if $('.dispute_check_box').not(':checked').length > 0
      $('#select-all-entries').prop('checked', false)
    else
      $('#select-all-entries').prop('checked', true)

    if $('.dispute_check_box:checked').length > 0
      $('#add-to-ticket-button').removeAttr('disabled')
    else
      $('#add-to-ticket-button').prop('disabled', 'disabled')

  window.close_modal = () ->
    $('#confirmation-modal').modal('toggle')

  window.build_checkbox_list = (arr, list, type) ->
    ####
    # the checkbox list for the dropdown is built here when the dropdown is first opened
    # because I don't want to type the same html element over and over + easier if drop in more vals without having to change it in multiple places
    ####
    for opt in arr
      checkbox =
        "<li> <label>
          <input name='#{opt}' value='#{opt}' type='checkbox' class='adjust_#{type}_checkbox'/>#{opt}
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
      check_name = "<span class='col-tag'>#{val}</span>"
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
    selected_rows = $('.col-select-all input:checked')
    $( selected_rows ).each ()->
      row = $( this ).closest('tr')
      $( row ).find('.col-actions').empty()
      $( row ).find('.col-clear-actions').empty()

  $('.wlbl_thrt_cat_id').on 'click', ->
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

  $(document).on 'click', '.col-actions .col-tag', (e) ->
    ####
    # handles deleting individual actions from an action column and reformatting the div it lives in + updating the data attribute of the action <p>
    ####

    { target } = e
    row = $(target).closest('tr')
    col_clear = $(row).find('.col-clear-actions')
    action = $(target).text()
    action_p = $(target).closest('p')
    action_edit = action_p.text().split(':')[0];
    data = $(action_p).attr('data').split(',')
    action_col = $(row).find('.row-action-clear')
    $(target).remove()

    data = data.filter((data_actions)-> return action != data_actions)
    col_dialog = "#{action_edit}: #{col_tag_format(data)}"

    $(action_p).attr('data', data)
    if data.length == 0
      if $(action_p).hasClass('wlbl-action-col')
        $(row).find('.threat-cat-col').remove()
      if $(action_p).hasClass('threat-cat-col')
        $(row).find('.wlbl-action-col').remove()
      $(action_p).remove()
      if $(action_col).html() == ''
        $(col_clear).find('button').click()
    else
      $(action_p).html(col_dialog)

  $(document).on 'change', '#select-all-bulk', (e) ->
    ####
    # handles selection of all checkboxes in quicklookup table
    ####
    e_val = e.currentTarget.checked
    select_cols = $('.col-select-all input')
    for col in select_cols
      $(col).prop('checked', e_val)

  $(document).on 'change', '.col-select-all input', (e) ->
    ####
    # handles selection of single checkboxes in quicklookup table
    ####
    select_cols = $('.col-select-all input')
    select_vals = []
    for col in select_cols
      select_vals.push( $(col).prop('checked') )
    bulk_value = select_vals.every( (col) -> return col)
    $('#select-all-bulk').prop('checked', bulk_value)

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

  $(document).on 'change', '.adjust_wlbl_checkbox', () ->
    # XXXXXXX
    submit_btn = $('#wlbl_entries_dropdown .dropdown-submit-button')
    all_checked_items = $('.adjust_wlbl_checkbox:checked')
    current_val = $(this).val()
    add_wlbl = $('#wlbl-reptool-add:checked').length > 0
    threat_cats = $('#wlbl_entries_dropdown .threat-cat-row')
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
        if checked > 0 && checked < 6
          disabled = false
      else
        $(wl_el.closest('li')).removeClass('grayed-out')

    if wl_check
      disabled = false

    if !bl_hide && add_wlbl
      $(threat_cats).removeClass('hidden')
    else
      $(threat_cats).addClass('hidden')

    submit_btn.prop('disabled', disabled)

  window.call_action_switchboard = (disputes) ->
    ####
    # data is set and each action calls the appropriate endpoint here
    ####
    comment = $('#confirmation-modal').find('.comment-input').text()
    $('#confirmation-modal').modal('hide')
    for dispute, value of disputes
      { action } = value
      if action != undefined
        for act in action
          for key, value of act
            switch key
              when ('maintain' || 'override')
                data = [{
                  'action': 'ACTIVE'
                  'entries': [dispute]
                  'classifications': act[key]
                  'comment': comment
                }]
                maintain_reptool_bl(data)
              when 'drop'
                data = {
                  'action': 'EXPIRED'
                  'entries': [dispute]
                  'comment':  comment
                  'classifications': act[key]
                }
                drop_reptool_bl(data)

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
                      { tc_ids } = el
                      data.thrt_cat_ids = tc_ids

                adjust_wlbl(data)

              when 'remove'
                data = {
                  'ip_uris': [dispute]
                  'list_types': act[key]
                  'note': comment
                }
                remove_wlbl(data)


  window.maintain_reptool_bl = (data)->
    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webrep/disputes/maintain_reptool_bl'
      data:
        data: data
      success_reload:false
      success: (response) ->
        $('#confirmation-modal').modal('hide')
        console.log response
    )

  window.drop_reptool_bl = (data) ->
    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webrep/disputes/drop_reptool_bl'
      data: data
      success_reload:false
      success: (response) ->
        $('#confirmation-modal').modal('hide')
        console.log response
    )

  window.adjust_wlbl = (data) ->
    console.log 'inininininin'
    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webrep/disputes/uri_wlbl'
      data: data
      success_reload:false
      success: (response) ->
        $('#confirmation-modal').modal('hide')
        console.log response
    )

  window.remove_wlbl = (data) ->
    console.log data
    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webrep/disputes/bulk_rule_ui_wlbl_remove'
      data: data
      success_reload:false
      success: (response) ->
        $('#confirmation-modal').modal('hide')
        console.log response
    )

  window.check_actions = (action_classes) =>

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
      else if stringIncludes(action_classes, 'add')
        return 'remove'
      else
        return 'tc_ids'

  window.quick_bulk_update = (data) ->
    password = $('form#top_banner_bugzilla_login_form').find('input[name=password]').val()
    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webrep/disputes/quick_bulk_update'
      data: {
        update_data: data
      }
      success_reload:false
      error_prefix: 'Error logging in.'
      success: (response) -> return response
    )

  window.stringIncludes = (str, substring) ->
    return str.indexOf(substring) != -1

  window.confirm_rep_changes = () ->
    ####
    #  confirm actions to be taken, data is prepared and  final submission of disputes to be made
    ####
    confirmation_rows = $('#confirmation-modal tbody').find('tr')
    comment = $('.confirm-rep-input').val()
    reptool_dispute_changes = []
    wlbl_dispute_changes = []
    disputes = {
      comment:$('.confirm-rep-input').text()
    }
    $( confirmation_rows ).each ->

      row = $( this ).find('td')
      dispute = $( row[0] ).text()
      actions = $( row[1] ).children()
      disputes[dispute] = dispute

      quick_bulk_update(disputes).then(
        ####
        # super simple endpoint to quick look up bulk submit-thus sayeth chris
        # on success, parse actions
        ####
        (response)=>
          data = JSON.parse(response).data
          dispute_entries = data.dispute_entries
          action_list = []
          for action, i in actions

            action_tags = []
            existing_classes = []
            existing_wlbl = []
            class_list = $(action).attr("class")

            maintain_check = stringIncludes(class_list, 'maintain')
            maintain_remove = stringIncludes(class_list, 'remove') && maintain_check
            drop_check = stringIncludes(class_list, 'drop')
            threat_cat = stringIncludes(class_list, 'threat-cat-col')

            if maintain_check || drop_check
              if $(action).attr('reptool_classes') != undefined
                existing_classes = $(action).attr('reptool_classes').split(',')
                if drop_check
                  action_tags = existing_classes

            if threat_cat
              tc_ids = $(action).attr('data').split(',')
              for tc_id in tc_ids
                action_tags.push( parseInt(tc_id) )
            else
              $(action).find('.col-tag').contents().each ->
                action_tags.push(this.data)
            formatted_action = check_actions(class_list)

            action_list.push( "#{formatted_action}": action_tags )
          actions = action: action_list
          disputes[dispute] = actions
      ).then( ()=>
        dispute_check = true
        for key, value of disputes
          if key != 'comment'
            if typeof value != 'object'
              dispute_check = false
              break
        if dispute_check
          call_action_switchboard(disputes)
      )

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
    list = $('#wlbl_entries_dropdown').find('ul')
    type = 'wlbl'
    wlbl_options = [ "WL-weak", "WL-med", "WL-heavy", "BL-weak", "BL-med", "BL-heavy"]

    if !$(list).has('label').length
      build_checkbox_list(wlbl_options, list, type)


  window.set_action_wlbl_col = () ->
    $('.grayed-out').removeClass('grayed-out')

    $('#error_modal').dialog()
    $('#error_modal .modal-body' ).empty()
    $('#error_modal').dialog( 'destroy' )

    selected_rows = $('.col-select-all input:checked')
    list_action = $('.wlbl-radio-add:checked').val()
    action_desc = 'Add to: '
    checked_bl = $('.adjust_wlbl_checkbox:checked').map( () -> return $(this).val() ).get()
    bl_check = checked_bl[0].indexOf('BL') != -1

    threat_cats_el = []
    threat_cats = []
    error_array = []

    if list_action == 'remove'
      action_desc = 'Remove from: '
    else
      action_desc = 'Add to: '

    if bl_check
      # if bl is checked, format threat cats for the dispute
      checked_tc = $('.wlbl_thrt_cat_id:checked')
      for check in checked_tc
        val = $(check).val()
        label = $(check).next('label').html()
        threat_cats.push("#{val}")
        threat_cats_el.push("<span data='#{val}' class='col-tag'>#{label}</span>")

    threat_cats = threat_cats.join()

    if threat_cats.length > 0
      threat_cats = "<p data='#{threat_cats}' class='threat-cat-col'> Threat Categories:#{threat_cats_el.join(', ')} </p>"
    else
      threat_cats = ''

    selected_rows.each ()->
      row = $(this).closest('tr')
      $(row).find('.wlbl-action-col').remove()
      $(row).find('.threat-cat-col').remove()
      selected_rows = $('.col-select-all input:checked')
      data = row.find('.col-bulk-dispute').text()

      if !isEmpty(data)
        error_message = "#{data}: "
        action_col = row.find('.col-actions')
        existing_p = ".#{list_action}  .wlbl-action-col"
        clear_col = row.find('.col-clear-actions')
        wlbl_col = row.find('.col-wlbl').text().replace(/ /g, '').split(',')
        tc_col = row.find('.col-threat-cats').text().split(', ')
        wlbl_err = ''
        tc_err = ''
        check_list_array = checked_bl.filter( (wlbl)->
          switch(list_action)
            when 'add'
              if wlbl_col.includes(wlbl)
                wlbl_err += "<span class='col-tag dialog-tag'>  #{wlbl}</span>, "
              return !wlbl_col.includes(wlbl)
            when 'remove'
              if !wlbl_col.includes(wlbl)
                wlbl_err += "<span class='col-tag dialog-tag'>  #{wlbl}</span>, "
              return wlbl_col.includes(wlbl)
        )
        threat_cat_array = threat_cats_el.filter( (tc)->
          if list_action == 'add'
            tc = $(tc).text().trim()
            if tc_col.includes(tc)
              tc_err += threat_cats_el + ', '
              tc_id = parseInt( $(threat_cats_el).data() )
              threat_cats_el.indexOf(tc)
              if (threat_cats_el.indexOf(tc)!= -1) then threat_cats_el.splice(index, 1)
              if (threat_cats.indexOf(tc)!= -1) then threat_cats.splice(index, 1)
            return !tc_col.includes(tc)
        )

        if wlbl_err != ''
          error_message += "<span>WLBL | #{wlbl_err.slice(0, wlbl_err.length - 2);}</span>"
        if tc_err != ''
          error_message += "<span> Threat Categories | #{tc_err.slice(0, tc_err.length - 2);}</span>"
        check_list = col_tag_format(check_list_array)
        col_dialog = "<p class='wlbl-action-col #{list_action}' data='#{check_list_array}'>#{action_desc}  #{check_list} #{threat_cats}<p>"
        delete_button = '<button class="clear-action-button row-action-clear"></button>'

        if error_message.endsWith('</span>')
          error_html = "<div>#{error_message}<div>"
          error_array.push(error_html)

        if check_list_array.length
          $(existing_p).remove()
          $(action_col).append(col_dialog)
          if !$(clear_col).has(".clear-action-button").length
            $(clear_col).append(delete_button)

    if  error_array.length
      $( '.error_modal' ).dialog({
        position:
          my: 'right',
          at: 'top+15%',
          of: window
      })
      $( '#error_modal .modal-header' ).html( "<h4>Cannot #{list_action} the following WLBL disputes <h4>" )
      $( '#error_modal .modal-body' ).append( error_array )
    submit_rep_check()

  wlbl_values= []
  reptool_values= []

  window.submit_quick_lookup = () ->
    $('#confirmation-modal tbody').empty()
    $('#confirmation-modal').modal()

    rows = $( '.col-select-all' ).closest('tr')
    confirmation_dialog = []

    $(rows).each ->
      new_data = $(this).find('.col-bulk-dispute').text()
      actions_col = $( this ).find('.col-actions')
      existing_reptool = ''
      rep_classes = actions_col.attr('reptool_classes')
      if rep_classes != undefined
        existing_reptool = "reptool_classes = #{rep_classes}"
      if !isEmpty(new_data) && new_data != undefined
        actions_col = $( this ).find('.col-actions')
        children = actions_col.children()
        existing_actions = actions_col
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
              html += "<div #{existing_reptool} #{threat_cat_data} class='#{classes}'>#{$(child).html()}</div>"
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
    $( '#error_modal' ).dialog(
      position:
        my: "right",
        at: "top+15%",
        of: window
    )
    $( '#error_modal .modal-body' ).empty()
    $( '#error_modal' ).dialog( 'destroy' )

    selected_rows = $( '.col-select-all input:checked' )
    check_vals = $( '.adjust_reptool_checkbox:checked' ).map( () -> return $(this).val() ).get()
    class_reptool = $( '.status_bl:checked' ).val().replace( 'reptool-' , '' )
    reptool_add  = $( '.reptool-add:checked' ).val()
    reptool_class = reptool_add

    switch (class_reptool)
      when 'maintain'
        reptool_dialog = reptool_add.charAt(0).toUpperCase() + reptool_add.slice(1)
        status_string = "#{reptool_dialog } classifications:"
        status_class = 'reptool-maintain-submission'
      when 'drop'
        status_string = 'Drop all classifications (set entry to EXPIRED)'
        reptool_add = 'drop'
        reptool_class = 'drop'
        check_list = ''
        status_class = 'reptool-drop-submission'
      when 'override'
        status_string = 'Add classifications: '
        status_class = 'reptool-override-submission'
        reptool_add  = $( '.reptool-add:checked' ).val()
        reptool_class = reptool_add

    error_array = []
    error_header = "<h4>Cannot #{reptool_add} the following Reptool Classification dispute<h4>"

    selected_rows.each () ->
      row = $(this).closest('tr')
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
          reptool_classes =  $(existing_reptool).text()
          $(action_col).attr( 'reptool_classes', reptool_classes )

      error_message = "#{data} :"
      if !isEmpty(data)

        if reptool_add == 'drop'
          if existing_reptool.length
            row.find( '.reptool-action-col' ).empty()
          else
            error_message = data + ' has no classifications to drop.'
        else
          $( '.drop.reptool-action-col' ).remove()
          actions = row.find('.col-actions')
          existing_actions = []

          if reptool_add.toLowerCase() == 'add'
            check_class = '.remove'
          else
            check_class = '.add'
            existing_actions = existing_actions.concat(rep_list)

          $(actions).find("#{check_class} .col-tag").each () -> existing_actions.push( this.innerText )

          if reptool_add.toLowerCase() == 'remove'
            check_list = check_vals.filter( (rep)->
              if !rep_list.includes(rep)
                error_message += "<span class='col-tag dialog-tag'>#{rep} </span>, "
              return rep_list.includes(rep)
            )
          else if reptool_add.toLowerCase() == 'add'
            check_list = check_vals.filter( (rep)->
              if existing_actions.includes(rep) || rep_list.includes(rep)
                error_message += "<span class='col-tag dialog-tag'>#{rep} </span>, "
              return !existing_actions.includes(rep) && !rep_list.includes(rep))

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
      disputes.splice(index, 1)
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
          "<tr>
            <td class='col-select-all'>
              <span class='checkbox-wrapper'>
                <input type='checkbox' checked>
              </span>
            </td>
            <td class='col-bulk-dispute' contenteditable='true' data='#{disputes[i]}'><p> #{disputes[i]} </p></td>
            <td class='col-wbrs'></td>
            <td class='col-wbrs-rule-hits'></td>
            <td class='col-wbrs-rules'></td>
            <td class='col-category'></td>
            <td class='col-wlbl'></td>
            <td class='col-threat-cats'></td>
            <td class='col-reptool-class'></td>
            <td class='col-actions' data=''></td>
            <td class='col-clear-actions'></td>
          </tr>"
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
    #THESE MAY NOT ACTUALLY BE NECESSARY, standby or details
    $(document).unbind('focusout')
    setTimeout () ->
      $( document ).on 'focusout', '.col-bulk-dispute', (e) -> set_row_text(e, this)
    , 250

  window.check_urls = (text_list, row) ->
    validated_urls = []
    errors = []
    ajax_count = text_list.length
    for url in text_list
      data = {'uri': url}
      $.ajax(
        url: '/escalations/api/v1/escalations/webrep/disputes/is_valid_url'
        method: 'GET'
        headers: headers
        data: data
        dataType: 'json'
        success: (response) ->
          ajax_count--
          {data, checked_url } = response
          if data
            validated_urls.push(checked_url)
          if ajax_count == 0
            buildRow(validated_urls, row)
      )



  set_row_text = (e, el) ->
    { which: key, type, shiftKey } = e

    text = el.innerText.trim()
    text_list = text.replace( /\n|\s/g, ", " ).split(", ")
    row = el.closest('tr')
    tbody = row.closest('tbody')

    text_list = text_list.filter (item, index) ->
      if item != ''
        return text_list.indexOf item == index
    if key == 13
      if !shiftKey && text_list.length
#          bindControls()
        check_urls(text_list, row)
    else if key == 0
      if text_list.length > 1
        check_urls(text_list, row)
      else
        $(row).data(text)
    else if key == 8
        if isEmpty(text) && $(tbody).children().length > 1
          $(row).remove()

  $( document ).on 'keydown focusout', '.col-bulk-dispute', (e) ->
    set_row_text(e, this)
    e.stopPropagation()

  $(document).bind( "ajaxStart", () ->
    $('.ajax-message-div').css('display','flex')
  )
  $(document).on 'click', '#get-rep-data', (e) ->
    e.preventDefault()
    search_items = []
    rows = $('.research-table tbody tr')

    $('.col-bulk-dispute').each ( ) ->
      text = $(this).text()
      if !isEmpty(text)
        search_items.push(text)

    for i in [0...search_items.length]
      item = search_items[i]
      row = rows[i]

      if !isEmpty(item)
        $('.ajax-message-div').css('display', 'flex')
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
        new get_threat_cat(item, headers)
          .then ( set_threat_cat.bind( null, item, row) )
          .then null, (err) -> console.log err
        new get_wrbs(item, headers)
          .then( set_wrbs.bind( null, item, row) )
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

  window.get_wrbs = (item, headers) ->
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
      success: (response) ->
        return response
      error: (response) -> return response
    )

  window.get_threat_cat = (item, headers) ->
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
    if data.length
      data = data.join(', ')
    col_wlbl.text( data )
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

  window.set_threat_cat = ( item, row, data) ->
    col_tc = $(row).children('.col-threat-cats')
    { threat_categories } = JSON.parse(data)
    if threat_categories.length
      text = threat_categories.join(', ')
    else
      text = 'No data'
      col_tc.addClass('missing-data')
    col_tc.text( text )

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