$ ->

  $('#new-dispute-form').submit (e) ->
    e.preventDefault()

    $('#loader-modal').modal({
      keyboard: false
    })

    ips_urls = this.ips_urls.value
    assignee = this.assignee.value
    priority = this.priority.value
    ticket_type = $('#ticket-type-dropdown')[0].value

    if ips_urls.trim.length > 0
      std_msg_ajax(
        url: '/escalations/api/v1/escalations/webrep/disputes'
        method: 'POST'
        data:
          ips_urls: ips_urls,
          assignee: assignee,
          priority: priority,
          ticket_type: ticket_type
        success: (response) ->
          $('#new-dispute').dropdown('toggle')
          $('#loader-modal').modal 'hide'

          if response.json.errors.length > 0
            std_msg_error("Duplicate",["Unable to create duplicate entries: #{response.json.errors}. The other entries (if any) were successfully created."], reload: true)

        error: (response) ->
          $('#loader-modal').modal 'hide'
          std_msg_error("Duplicate",[response.responseJSON.message], reload: false)
      )
    else
      $('#loader-modal').modal 'hide'
      std_msg_error("Error",["Cannot submit form while URLs/IP Addresses field is empty. "])

  $('#cancel_dispute').on 'click', ->
    $('#ips_urls').val('')
    $('#assignee').val('')
    $('#new-dispute').dropdown('toggle')