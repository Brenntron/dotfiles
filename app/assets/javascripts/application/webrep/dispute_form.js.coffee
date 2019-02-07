$ ->

  $('#new-dispute-form').submit (e) ->
    e.preventDefault()

    $('#loader-modal').modal({
      backdrop: 'static',
      keyboard: false
    })

    $('#loader-modal').show()

    ips_urls = this.ips_urls.value
    assignee = this.assignee.value
    priority = this.priority.value
    ticket_type = this.ticket_type.value

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
        $('#loader-modal').hide()

        data = {
          search_type: 'advanced'
          case_id: response.json.case_id
        }

        window.populate_webrep_index_table(data)
      error: (response) ->
        $('#loader-modal').hide()
        $('.modal-backdrop').remove();
        std_api_error(response, "Dispute was not created.", reload: false)
    )

  $('#cancel_dispute').on 'click', ->
    $('#ips_urls').val('')
    $('#assignee').val('')
    $('#new-dispute').dropdown('toggle')