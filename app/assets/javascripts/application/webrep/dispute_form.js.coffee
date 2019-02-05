$ ->
  $('#new-dispute-form').submit (e) ->
    e.preventDefault()

    $('#loader-modal').modal({
      backdrop: 'static',
      keyboard: false
    })

    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    ips_urls = this.ips_urls.value
    assignee = this.assignee.value
    priority = this.priority.value
    ticket_type = this.ticket_type.value

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes'
      method: 'POST'
      headers: headers
      data:
        ips_urls: ips_urls,
        assignee: assignee,
        priority: priority,
        ticket_type: ticket_type
      success: (response) ->
        $('#loader-modal').hide()
        std_msg_success('Dispute Created.', [], reload: true)
      error: (response) ->
        $('#loader-modal').hide()
        $('.modal-backdrop').remove();
        std_api_error(response, "Dispute was not created.", reload: false)
    )