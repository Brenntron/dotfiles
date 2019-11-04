$ ->
  window.reset_form = (form) ->
    user = form.find('#assignee').prop("defaultValue")
    form.find('.ips_urls').val('');
    form.find('#priority').val('P3');
    form.find('#assignee').val(user);
    form.find('#ticket-type-dropdown').val('Web');

  window.ips_textarea_toggle = (dropdown) ->
    if !$(dropdown).is('a')
      $('#research-page-toolbar .ips_urls').addClass('hidden')
      $('#research-page-toolbar .ips_urls_div').removeClass('hidden')

  window.submit_research_query = () ->
    $('.ajax-message-div').css( 'margin-top',' -33px')
    $('.ajax-message-div').css('display', 'flex')

  window.submit_new_dispute = (submit_btn) ->
    $('.ajax-message-div').css( 'margin-top',' -33px')
    $('.ajax-message-div').css('display', 'flex')

    data = {}
    form = $(submit_btn).closest('form')
    form_values = form.serializeArray()
    text_area = form.find('.ips_urls')
    dropdown = $(submit_btn).closest(".dropdown-menu").prev()
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
              std_msg_error("Duplicate",["#{message_html} <p class='ugh'>The following duplicate entries were not processed</p> <div class='dupe_list'>#{errors.join(', ')}</div> "], reload: false)
          else
            ips_list = ''
            for ips in ips_urls
              ips_list += '<span>' + ips + '</span>'
              message_html =
                "<p>The following entries referenced are on ticket number " + ticket_num + "</p>" +
                "<p class='dupe_list'>" + ips_list + "</p>"
              reset_form(form)
              std_msg_success('All entries were successfully created.', [message_html], reload: false)


        error: (response) ->
          if response.responseJSON.message.includes('duplicates')
            error_list = response.responseJSON.message.split(': ')[1].trim().split(' ')
            message =
              "<p>Unable to create the following duplicate dispute entries: </p>" +
              "<p class='dupe_list'>" + error_list.join(' ') + "</p>"
          else
            message = response.responseJSON.message

          std_msg_error("Error",[ message], reload: false)
      )
    else
      std_msg_error("Error",["Cannot submit form while URLs/IP Addresses field is empty. "])

  $('.cancel_dispute').on 'click', ->
    $(this).find('.ips_urls').val('')
    $(this).find('.assignee').val('')
    $(dropdown).dropdown 'toggle'