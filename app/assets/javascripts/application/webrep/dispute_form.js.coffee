$ ->
  window.submit_new_dispute = (submit_btn) ->
    console.log 'in'
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
      console.log 'we in here'
      std_msg_ajax(
        url: '/escalations/api/v1/escalations/webrep/disputes'
        method: 'POST'
        data: data
        success: (response) ->
          console.log 'success response', response
          {case_id, errors } = response.json
          ticket_num = '<a href="/escalations/webrep/disputes/' + case_id + '#research_tab">' + case_id + '</a>'
          ips_urls = data.ips_urls.replace(/\n/g, ",").split(",")

          $(dropdown).dropdown 'toggle'
          $('#loader-modal').modal 'hide'

          if errors.length > 0
            successful_entries = []
            if ips_urls not in errors
              successful_entries.push(ips_urls)
            if successful_entries > 0
              std_msg_error("Duplicate",["Unable to create duplicate entries: #{errors}. The other entries (#{successful_entries}) were successfully created."], reload: true)
            else
              std_msg_error("Duplicate",["Unable to create duplicate entries: #{errors}."], reload: true)
          else
              url_list = ""
              for url in ips_urls
                url_list += '<li>' + url + '</li>'
              url_list = '<ul>' + url_list + '</ul>  '
              message_html =
                "<p>The following entries referenced on ticket number " + ticket_num + "</p>" +
                "<p>" + url_list + "</p>"
              std_msg_success('All entries were successfully created.', [message_html])
        error: (response) ->
          $('#loader-modal').modal 'hide'
          console.log 'success response', response
          std_msg_error("Error",[response.responseJSON], reload: false)
      )

    else
      $('#loader-modal').modal 'hide'
      std_msg_error("Error",["Cannot submit form while URLs/IP Addresses field is empty. "])

  $('#cancel_dispute').on 'click', ->
    $('#ips_urls').val('')
    $('#assignee').val('')
    $(dropdown).dropdown 'toggle'