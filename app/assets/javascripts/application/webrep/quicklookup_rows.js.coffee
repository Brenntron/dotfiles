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

      $(tbody).find('tr .col-bulk-dispute').each ->
        if isEmpty( $(this).attr('data') )
          this.focus()

      setTimeout () ->
        $("br").remove()
      , 20
    $('.ajax-message-div').css('display', 'none')


  window.bindControls = () ->
# unbind and rebind blur to prevent the rebuilding of the table from being stuck in a loop
    $(document).off('blur', '.col-bulk-dispute')
    setTimeout () ->
      $( document ).on 'blur', '.col-bulk-dispute', (e) -> set_row_text(e, this)
    , 250

  window.check_urls = (text_list, row, data) ->
    checked = data.data
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
            buildRow(valid_list, row)
      )
    else
      buildRow(valid_list, row)
      return true

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
    { which: key, shiftKey } = e
    text = el.innerText.trim()
    text_list = text.replace( /\n|\s/g, ", " ).split(", ")
    row = el.closest('tr')
    tbody = row.closest('tbody')

    text_list = text_list.filter (item, index) ->
      if item != ''
        return text_list.indexOf item == index
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
      if isEmpty(text) && $(tbody).children().length > 1
        $(row).remove()

  $( document ).on 'keydown blur', '.col-bulk-dispute', (e) ->
    set_row_text(e, this)
    e.stopPropagation()
  