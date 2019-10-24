$ ->
  window.reset_form = (form) ->
    user = form.find('#assignee').prop("defaultValue")
    form.find('#ips_urls').val('');
    form.find('#priority').val('P3');
    form.find('#assignee').val(user);
    form.find('#ticket-type-dropdown').val('Web');

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
      data.ips_urls = data.ips_urls.replace(/,/g, '').replace(/\n/g, ' ')
      std_msg_ajax(
        url: '/escalations/api/v1/escalations/webrep/disputes'
        method: 'POST'
        data: data
        success_reload: false
        success: (response) ->
          { case_id, errors } = response.json
          ticket_num = '<a href="/escalations/webrep/disputes/' + case_id + '#research_tab">' + case_id + '</a>'
          ips_urls = data.ips_urls.split(' ')
          ips_urls = ips_urls.map( (url) => return url.trim())

          $(dropdown).dropdown 'toggle'
          $('#loader-modal').modal 'hide'
          if errors.length > 0
            errors = errors.map( (err) => return err.trim())
            successful_entries = []
            for url in ips_urls
              url = url.trim()
              if url not in errors
                successful_entries.push(url)
            if successful_entries.length > 0
              message_html =
                "<p >The following entries referenced on ticket number " + ticket_num + "</p>" +
                "<p class='dupe_list'>" + successful_entries.join(', ') + "</p>"
              reset_form(form)
              std_msg_error("Duplicate",["#{message_html} <p class='ugh'>The following duplicate entries were not processed</p> <div class='dupe_list'>#{errors.join(', ')}</div> "], reload: true)
          else
              message_html =
                "<p class='ugh'>The following entries referenced are on ticket number " + ticket_num + "</p>" +
                "<p class='dupe_list'>" + ips_urls.join(', ') + "</p>"
              reset_form(form)
              std_msg_success('All entries were successfully created.', [message_html], reload: true)


        error: (response) ->
          $('#loader-modal').modal 'hide'
          reset_form(form)
          error_list = response.responseJSON.message.split(': ')[1].trim().split(' ')
          message_html =
            "<p>Unable to create the following duplicate dispute entries: </p>" +
            "<p class='dupe_list'>" + error_list.join(', ') + "</p>"
          std_msg_error("Error",[ message_html], reload: false)
      )
    else
      $('#loader-modal').modal 'hide'
      std_msg_error("Error",["Cannot submit form while URLs/IP Addresses field is empty. "])

  $('#cancel_dispute').on 'click', ->
    $('#ips_urls').val('')
    $('#assignee').val('')
    $(dropdown).dropdown 'toggle'