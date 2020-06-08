$ ->
  headers =  'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val()

  $('body').on 'mouseenter', '.tc_data:not(.tooltipstered)', ->
    $(this).tooltipster(
      side: 'bottom'
      interactive: true
      theme: ['tooltipster-borderless', 'tooltipster-borderless-customized']
    ).tooltipster 'open'

  window.buildRow = ( text_list, parent_row) ->
# build and append new rows to the HTML in quick lookup
    bindControls()
    # Once the table has been rebuilt, find the empty row and focus on it
    tbody = document.querySelector('.research-table tbody')
    disputes = []
    disputes_data = []
    existing_rows = $(tbody).find('tr')
    parent_data = $(parent_row).find('.col-bulk-dispute').attr('data')
    parent_index = parent_row.rowIndex
    prev_row = existing_rows.eq(parent_index - 2)[0].innerText
    $(existing_rows).each ->
      data = $(this).find('.col-bulk-dispute').attr('data')
      text_list = text_list.filter( (text)-> return !text_list.includes(data) )

      if !isEmpty(data)
        disputes_data.push(data)
        disputes.push(this)
#    if !isEmpty(parent_data) && text_list.includes(parent_data)
#      index = disputes.indexOf(parent_data)
#      disputes.splice(index, 1)
#      parent_index = parent_index - 1
    if text_list[0] != ''
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

#    for dispute in disputes

    for i in [0...disputes.length]
# if the dispute is not an HTML object, set the HTML of the new row to the below
      if typeof disputes[i] != 'object'
        $('#add_addtional_row').css('display', 'none')
        tbody.innerHTML +=
          "<tr>
            <td class='col-select-all'>
              <span class='checkbox-wrapper'>
                <input type='checkbox' checked='true'>
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
      get_rep_check()
      $(tbody).find('tr .col-bulk-dispute').each ->
        data = $(this).attr('data')
        if isEmpty( data )
          this.focus()
        else
          $(this).text(data)

      setTimeout () ->
        $("br").remove()
      , 20


  window.bindControls = () ->
# unbind and rebind blur to prevent the rebuilding of the table from being stuck in a loop
    $(document).off('blur', '.col-bulk-dispute')
    setTimeout () ->
      $( document ).on 'blur', '.col-bulk-dispute', (e) -> set_row_text(e, this)
    , 250

  window.check_urls = (text_list, row, data) ->
    checked = data.data
    existing_rows = $("#research-table tbody").find('tr')
    urls = []
    valid_list = []
    for name, value of checked
      if !value
        urls.push(name)
      else
        valid_list.push(name)
    if urls.length
      data = {'uri': urls}
      $.ajax(
        url: '/escalations/api/v1/escalations/webrep/disputes/is_valid_url'
        method: 'GET'
        headers: headers
        data: data
        dataType: 'json'
        success: (response) ->
          {status, data } = response
          if status == 'success'
            for name, value of data
              if value
                valid_list.push(name)
            check_row_data(valid_list, row)
      )
    else
      check_row_data(valid_list, row)

  window.check_row_data = (valid_list, row) ->
    existing_rows = $("#research-table tbody").find('tr')
    disp_data =  $(row).find('.col-bulk-dispute').attr('data')
    single_row = valid_list[0] != disp_data
    existing_rows.each ->
      data = $(this).find('.col-bulk-dispute').attr('data')
      if data == valid_list[0]
        valid_list = ['']
    if valid_list.length == 1 && single_row && disp_data != ""
      $(row).find('.col-bulk-dispute').attr('data', valid_list[0])
      $(row).find('.col-bulk-dispute').removeAttr('searched')
      $(row).find('.row-action-clear').click()
      $(row).find('.col-wbrs-rule-hits, .col-wbrs-rules, .col-category, .col-wlbl, .col-threat-cats, .col-wbrs, .col-reptool-class').text('')
    buildRow(valid_list, row)

  window.check_ips = (text_list) ->
    data = {'ip_address': text_list}
    $.ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/is_valid_ip'
      method: 'GET'
      headers: headers
      data: data
      dataType: 'json'
      success: (response) -> return response
    )

  set_row_text = (e, el) ->
    { which: key, shiftKey, type } = e
    text = el.innerText.trim()

    get_rep_check(e)
    if text != undefined
      text_list = text.split(/[\s\t\n]+/)
      row = el.closest('tr')
      tbody = row.closest('tbody')

      text_list = text_list.filter (item, index) ->
        if item != ''
          return text_list.indexOf item == index
      if type == 'focusout'
        if !shiftKey && text_list.length
          check_ips(text_list, headers, row)
            .then ( check_urls.bind( null, text_list, row) )
            .then null, (err) -> console.log err

      if key == 13
        if !shiftKey && text_list.length
          check_ips(text_list, headers, row)
            .then ( check_urls.bind( null, text_list, row) )
            .then null, (err) -> console.log err
      else if key == 0
        if text_list.length > 1
          check_ips(text_list, headers, row)
            .then ( check_urls.bind( null, text_list, row) )
            .then null, (err) -> console.log err
        else
          $(row).data(text)
      else if key == 8
        length_check = isEmpty(text) || text.length == 1
        if length_check && $(tbody).children().length > 1
          $(row).remove()
          if !isEmpty( $(tbody).find('tr').last() )
            $('#add_addtional_row').css('display', 'flex')
          else
            $('#add_addtional_row').css('display', 'none')

  $(document).on 'click', '#add_addtional_row', ->
    row =
      "<tr>
            <td class='col-select-all'>
              <span class='checkbox-wrapper'>
                <input type='checkbox' checked>
              </span>
            </td>
            <td class='col-bulk-dispute' contenteditable='true' data=' '><p> </p></td>
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
    $('#add_addtional_row').css('display', 'none')
    $('#research-table').append(row)

  $( document ).on 'keydown blur', '.col-bulk-dispute', (e) ->
    console.log 'in', e
    set_row_text(e, this)
    e.stopPropagation()
