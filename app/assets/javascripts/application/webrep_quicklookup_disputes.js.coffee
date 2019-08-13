
$ ->
  completed_counter = 0
  $(document).bind(
    ajaxStart: () ->
      $('.ajax-message-div').css('display', 'flex')
    ajaxComplete: () ->
      completed_counter++
      selected_rows = $('.col-select-all input:checked').length * 4 - 1
      if completed_counter == selected_rows
        $('.ajax-message-div').hide()
  )

  $(document).on 'click', '#clear-all-actions', (e) ->
    e.preventDefault()
    selected_rows = $('.col-select-all input:checked')
    $( selected_rows ).each ()->
      row = $( this ).closest('tr')
      $( row ).find('.col-actions').empty()
      $( row ).find('.col-clear-actions').empty()

  $(document).on 'click', '.row-action-clear', (e) ->
    e.preventDefault()
    { target } = e
    row = $(target).closest('tr')
    col_actions = row.find('.col-actions')
    $(target).remove()
    $( col_actions ).empty()
    submit_rep_check()

  $(document).on 'click', '.col-actions .col-tag', (e) ->
    { target } = e
    action = $(target).text()
    action_p = $(target).closest('p')
    action_edit = action_p.text().split(':')[0];
    data = $(action_p).attr('data').split(',')
    $(target).remove()

    data = data.filter((data_actions)-> return action != data_actions)
    col_dialog = action_edit + ': ' + col_tag_format(data)

    $(action_p).attr('data', data)
    $(action_p).html(col_dialog)

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

  $(document).on 'change', '.adjust_wlbl_checkbox', () ->
    submit_btn = $('#wlbl_entries_dropdown .dropdown-submit-button')
    if $('.adjust_wlbl_checkbox:checked').length
      submit_btn.prop('disabled', false)
    else
      submit_btn.prop('disabled', true)


  window.confirm_rep_changes = () ->
    confirmation_rows = $('#confirmation-modal tbody').find('tr')
    comment = $('.confirm-rep-input').val()
    reptool_dispute_changes = []
    wlbl_dispute_changes = []

    $( confirmation_rows ).each ->
      dispute = $( this ).find('td').first().text()
      action_col = $( this ).find('td').last().children()

      for action in action_col
        classList = $(action).attr('class').split(/\s+/)
        def_list = []
        action_taken = classList.filter( (el)-> ['add', 'remove', 'drop'].includes(el)).join()
        $(action).find('.col-tag').each -> def_list.push( $(this).text() )

        if $(action).hasClass('reptool-action-col')
          if typeof $(action).attr('class') == 'string'
            submission_action = classList.filter( ( class_list )-> return class_list.endsWith('-submission')).join().replace('-submission','')

          if reptool_dispute_changes.length
            existing_dispute = false

            for i in [0...reptool_dispute_changes.length]
              { action, classifications } = reptool_dispute_changes[i]
              class_check = JSON.stringify(classifications) == JSON.stringify(def_list)
              action_check = action == action_taken

              if action_check && class_check
                existing_dispute = true
                reptool_dispute_changes[i].entries.push(dispute)

            if !existing_dispute
              data = {
                entries: [dispute]
                classifications: def_list
                classification_action: action_taken
                submission_action: submission_action
                comment: comment
              }
              reptool_dispute_changes.push(data)
          else
            data = {
              entries: [dispute]
              classifications: def_list
              submission_action: submission_action
              comment: comment
            }
            reptool_dispute_changes.push(data)

        else
          wlbl_existing_dispute = false

          if wlbl_dispute_changes.length
            wlbl_existing_dispute = false

            for i in [0...wlbl_dispute_changes.length]
              { action, classifications } = wlbl_dispute_changes[i]
              class_check = JSON.stringify(classifications) == JSON.stringify(def_list)
              action_check = action == action_taken
              if action_check && class_check
                wlbl_existing_dispute = true
                wlbl_dispute_changes[i].entries.push(dispute)

            if !wlbl_existing_dispute
              data = {
                action:  action_taken
                entries: [dispute]
                classifications: def_list
                comment: comment
              }
              wlbl_dispute_changes.push(data)
          else
              data = {
                action:  action_taken
                entries: [dispute]
                classifications: def_list
                comment: comment
              }
              wlbl_dispute_changes.push(data)

    wlbl_dispute_changes = wlbl_dispute_changes.filter( (x)-> return x != undefined )
    reptool_dispute_changes = reptool_dispute_changes.filter( (x)-> return x != undefined )

  window.close_modal = () ->
    $('#confirmation-modal').modal('toggle')

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
    wlbl_options = [ "WL-weak", "WL-med", "WL-heavy",
      "BL-weak", "BL-med", "BL-heavy"]
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
    selected_rows = $('.col-select-all input:checked')
    $('#error_modal').dialog()
    $( '#error_modal .modal-body' ).empty()
    $('#error_modal').dialog( "destroy" )
    list_action = $('.wlbl-radio-add:checked').val()
    list_class = '.' + list_action
    action_desc = 'Add to: '
    if list_action == 'remove'
      action_desc = 'Remove from: '
    checked_bl = $('.adjust_wlbl_checkbox:checked').map( () -> return $(this).val() ).get()
    error_array = []
    error_header = '<h4>Cannot ' + list_action + ' the following Reptool Classification disputes <h4> '
    selected_rows.each ()->
      row = $(this).closest('tr')
      selected_rows = $('.col-select-all input:checked')
      data = row.find('.col-bulk-dispute').text()
      if !isEmpty(data)
        error_message = data + ': '
        action_col = row.find('.col-actions')
        existing_p = action_col.find( list_class + '.wlbl-action-col')
        clear_col = row.find('.col-clear-actions')
        wlbl_col = row.find('.col-wlbl').text().replace(/ /g, '').split(',')

        check_list_array = checked_bl.filter( (wlbl)->
          switch(list_action)
            when 'add'
              if wlbl_col.includes(wlbl)
                error_message += '<span class="col-tag dialog-tag">' + wlbl + '</span>, '
              return !wlbl_col.includes(wlbl)
            when 'remove'
              if !wlbl_col.includes(wlbl)
                error_message += '<span class="col-tag dialog-tag">' + wlbl + '</span>, '
              return wlbl_col.includes(wlbl)
        )

        check_list = col_tag_format(check_list_array)
        col_dialog = "<p class='wlbl-action-col " +  list_action + "' data='" + check_list_array + "'>" + action_desc + check_list + "<p>"
        delete_button = '<button class="clear-action-button row-action-clear"></button>'
        if error_message.endsWith(', ')
          error_message = error_message.slice(0, error_message.length - 2);
          error_html = '<div>' + error_message + '<div>'
          error_array.push(error_html)
        if check_list_array.length
          $(existing_p).remove()
          $(action_col).append(col_dialog)
          if !$(clear_col).has(".clear-action-button").length
            $(clear_col).append(delete_button)

    if  error_array.length
      $( '.error_modal' ).dialog(
        position:
          my: "right",
          at: "top+15%",
          of: window
      )
      $( '#error_modal .modal-header' ).html( error_header )
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
      if actions_col.attr('reptool_classes') != undefined
        existing_reptool = 'reptool_classes =' + actions_col.attr('reptool_classes')

      if !isEmpty(new_data) && new_data != undefined
        actions_col = $( this ).find('.col-actions')
        children = actions_col.children()
        existing_actions = actions_col
        if children.length

          html =
            '<tr> <td>' +
            new_data +
            '</td> <td>'

          for child in children
            classes = $(child).attr("class")
            if !isEmpty(classes) && classes != undefined
              html +=  '<div ' + existing_reptool + ' class="' + classes + '">' + $(child).html() + '</div>'

          html += '</td> </tr>'

          confirmation_dialog.push( html )

    $('#confirmation-modal tbody').append(confirmation_dialog)

  window.col_tag_format = (array) ->
    if typeof array == 'string'
      array = array.split(',')
    check_list_array = []
    check_list = ''
    for val in array
      check_name = "<span class='col-tag'>" + val + "</span> "
      check_list_array.push(check_name)
    if check_list_array.length == 2
      check_list = check_list_array.join(' and ')
    else
      check_list = check_list_array.join(', ').replace(/, ([^,]*)$/, ', and $1')
    return check_list

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
        status_string = reptool_dialog + ' classifications: '
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
    error_header = '<h4>Cannot ' + reptool_add + ' the following Reptool Classification disputes <h4> '

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
        if class_reptool == 'maintain' && existing_reptool.length && !isEmpty(data)
          reptool_classes =  $(existing_reptool).text()
          $(action_col).attr( 'reptool_classes', reptool_classes )

      error_message = data + ': '
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

          $(actions).find(check_class + ' .col-tag').each () -> existing_actions.push( this.innerText )

          if reptool_add.toLowerCase() == 'remove'
            check_list = check_vals.filter( (rep)->
              if !rep_list.includes(rep)
                error_message += '<span class="col-tag dialog-tag">' + rep + '</span>, '
              return rep_list.includes(rep)
            )
          else if reptool_add.toLowerCase() == 'add'
            check_list = check_vals.filter( (rep)->
              if existing_actions.includes(rep) || rep_list.includes(rep)
                error_message += '<span class="col-tag dialog-tag">' + rep + '</span>, '
              return !existing_actions.includes(rep) && !rep_list.includes(rep))
          else

        clear_col = $( row.find('.col-clear-actions') )
        existing_p = action_col.find('.' + reptool_class + '.reptool-action-col')
        delete_button = '<button class="clear-action-button row-action-clear"></button>'
        if error_message.endsWith(', ')
          error_message = error_message.slice(0, error_message.length - 2);
          error_html = '<div>' + error_message + '<div>'
          error_array.push(error_html)
        else if error_message.includes('has no classifications to drop')
          error_html = '<div>' + error_message + '<div>'
          error_array.push(error_html)

        col_dialog = "<p class='" + reptool_class + ' ' + status_class + " reptool-action-col' data=' " + check_list + " '>" + status_string + col_tag_format(check_list) + "<p>"
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
            '<td class="col-clear-actions"></td>' +
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

    text_list = text_list.filter (item, index) ->
      if item != ''
        return text_list.indexOf item == index

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

  $(document).bind( "ajaxStart", () ->
    console.log 'in'
    $('.ajax-message-div').css('display','flex')
  )
  $(document).on 'click', '#get-rep-data', (e) ->
    e.preventDefault()
    search_items = []
    rows = $('.research-table tbody tr')
    headers = { 'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val() }

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