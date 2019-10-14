$ ->
  window.submit_new_dispute = (submit_btn) ->
    data = {}
    form = $(submit_btn).closest('form')
    form_values = form.serializeArray()
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
        success_reload: false
        success: (response) ->
          { case_id, errors } = response.json
          ticket_num = '<a href="/escalations/webrep/disputes/' + case_id + '#research_tab">' + case_id + '</a>'
          ips_urls = data.ips_urls.replace(/\n/g, ",").split(",")
          $(dropdown).dropdown 'toggle'
          $('#loader-modal').modal 'hide'
          if errors.length > 0
            successful_entries = []
            for url in ips_urls
              if url not in errors
                successful_entries.push(url)

            if successful_entries.length > 0
              url_list = ""
              for url in successful_entries
                url_list += '<li>' + url + '</li>'
              url_list = '<ul>' + url_list + '</ul>'

              message_html =
                "<p>The following entries referenced on ticket number " + ticket_num + "</p>" +
                "<p>" + url_list + "</p>"
              std_msg_error("Duplicate",["Duplicate entries were not processed <br/><span class='ugh'>#{errors.join(', ')}</span>  #{message_html}"], reload: true)
          else
              url_list = ""
              for url in ips_urls
                url_list += '<li>' + url + '</li>'
              url_list = '<ul>' + url_list + '</ul>  '
              message_html =
                "<p class='ugh'>The following entries referenced on ticket number " + ticket_num + "</p>" +
                "<p>" + url_list + "</p>"
              std_msg_success('All entries were successfully created.', [message_html], reload: true)
          form.trigger('reset');
        error: (response) ->
          $('#loader-modal').modal 'hide'
          std_msg_error("Error",[response.responseJSON.message], reload: false)
          form.trigger('reset');
      )
    else
      $('#loader-modal').modal 'hide'
      std_msg_error("Error",["Cannot submit form while URLs/IP Addresses field is empty. "])

  $('#cancel_dispute').on 'click', ->
    $('#ips_urls').val('')
    $('#assignee').val('')
    $(dropdown).dropdown 'toggle'