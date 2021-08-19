$ ->
  window.reset_webrep_form = (form) ->
    user = form.find('#assignee').prop("defaultValue")
    form.find('.ips_urls').val('');
    form.find('#priority').val('P3');
    form.find('#assignee').val(user);
    form.find('#ticket-type-dropdown').val('Web');

  window.ips_textarea_toggle = (dropdown) ->
    if !$(dropdown).is('a')
      $('#research-page-toolbar .ips_urls').addClass('hidden')
      $('#research-page-toolbar .ips_urls_div').removeClass('hidden')

  window.submit_new_dispute = (submit_btn) ->
    data = {}
    urls_array = []   # used for url validation
    invalid_uri_exists = false

    form = $(submit_btn).closest('form')
    form_values = form.serializeArray()

    for item in form_values
      { name, value } = item

      name = name.toLowerCase().replace(/-/g, '_')
      if name != 'token' && name != 'xml_token' && name != 'current_user'
        data[name] = value

    # entries will be either separated by newlines
    if data.ips_urls.indexOf('\n') > 0
      urls_array = data.ips_urls.split('\n')
    else
      urls_array.push(data.ips_urls)

    # ensure each url/ip has no spaces (edge case)
    $(urls_array).each ->
      curr_url = this
      curr_url = curr_url.trim().replace(/\r/g, '')  # carriage returns

      if curr_url.includes(' ')
        $('.dispute-error-inline').removeClass('hidden')  # show error msg about spaces
        invalid_uri_exists = true

    # exit the function if a bad uri exists
    if invalid_uri_exists then return

    $('.dispute-error-inline').addClass('hidden')  # ensure inline message is not showing

    if data.ips_urls.trim().length > 0
      data.ips_urls = data.ips_urls.replace(/,/g, '').replace(/\n/g, ' ')

      std_msg_ajax(
        url: '/escalations/api/v1/escalations/webrep/disputes'
        method: 'POST'
        data: data
        success_reload: false
        success: (response) ->
          { case_id, errors } = response.json

          ticket_num = "<a href='/escalations/webrep/disputes/#{case_id}#research_tab'>#{case_id}</a>"
          ips_urls = data.ips_urls.split(' ').map( (url) => return url.trim())

          $(submit_btn).closest(".dropdown-menu").prev().dropdown('toggle')

          if errors.length > 0
            errors = errors.map( (err) => return err.trim())
            successful_entries = []

            for url in ips_urls
              url = url.trim()
              if url not in errors
                successful_entries.push(url)

            if successful_entries.length > 0
              message_html = "<p >The following entries referenced on ticket number #{ticket_num} </p> <p class='dupe_list'>#{ successful_entries.join(', ') }</p>"
              reset_webrep_form(form)
              std_msg_error("Duplicate",["#{message_html} <p>The following duplicate entries were not processed</p> <div class='dupe_list'>#{errors.join(', ')}</div> "], reload: false)

          else
            ips_list = ''

            for ips in ips_urls
              ips_list += "<span>#{ips}</span>"
              message_html = "<p>The following entries referenced are on ticket number #{ticket_num}</p> <p class='dupe_list'>#{ips_list}</p>"
              reset_webrep_form(form)
              std_msg_success('All entries were successfully created.', [message_html], reload: false)


        error: (response) ->
          if response.responseJSON.message.includes('duplicates')
            error_list = response.responseJSON.message.split(': ')[1].trim().split(' ')
            message = "<p>Unable to create the following duplicate dispute entries: </p> <p class='dupe_list'>#{error_list.join(' ')}</p>"
          else
            message = response.responseJSON.message
          std_msg_error("Error",[ message], reload: false)
      )
    else
      std_msg_error("Error",["Cannot submit form while URLs/IP Addresses field is empty. "])

  $('.cancel_dispute').on 'click', ->
    $(this).find('.ips_urls').val('')
    $(this).find('.assignee').val('')
    $('#new-dispute').dropdown 'toggle'

  $('.new-dispute-close').click ->
    $('.dispute-error-inline').addClass('hidden')
