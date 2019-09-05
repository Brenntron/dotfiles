$ ->
  window.submit_new_dispute = (submit_btn) ->
    data = {}
    form_values = $(submit_btn).closest('form').serializeArray()
    dropdown = $(submit_btn).closest(".dropdown-menu").prev()
    $('#loader-modal').modal({
      keyboard: false
    })

    for item in form_values
      { name, value } = item
      name = name.toLowerCase().replace(/-/g, '_')
      if name != 'token' && name != 'xml_token' && name != 'current_user'
        data[name] = value

    if data.ips_urls.trim().length > 0
      std_msg_ajax(
        url: '/escalations/api/v1/escalations/webrep/disputes'
        method: 'POST'
        data: data
        success: (response) ->
          $(dropdown).dropdown 'toggle'
          $('#loader-modal').modal 'hide'
          if response.json.errors.length > 0
            std_msg_error("Duplicate",["Unable to create duplicate entries: #{response.json.errors}. The other entries (if any) were successfully created."], reload: true)
          else
            std_msg_success('All entries were successfully created.', [])
        error: (response) ->
          $('#loader-modal').modal 'hide'
          std_msg_error("Error",[response.responseJSON.message], reload: false)
      )

    else
      $('#loader-modal').modal 'hide'
      std_msg_error("Error",["Cannot submit form while URLs/IP Addresses field is empty. "])

  $('#cancel_dispute').on 'click', ->
    $('#ips_urls').val('')
    $('#assignee').val('')
    $(dropdown).dropdown 'toggle'