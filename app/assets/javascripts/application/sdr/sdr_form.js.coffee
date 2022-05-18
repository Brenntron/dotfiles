$ ->

  $('#new-sdr-dispute').on 'click', ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/customers'
      method: 'GET'
      dataType: 'json'
      headers: headers
      success: (response) ->
        $('#sdr-customer-list').empty()
        for data, i in response.data
          $('#sdr-customer-list').append '<option value="' + data + '"></option>'
    )

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/platforms_names'
      method: 'GET'
      success: (response) ->
        $('#sdr-platform-list').empty()
        for platform in response.data
          $('#sdr-platform-list').append '<option value="' + platform + '"></option>'
    )

  $('#cancel_sdr_dispute').on 'click', ->
    $(':input','#new-sdr-dispute-form').val('')
    $('#new-sdr-dispute-form #priority').val('P3') #set Priority back to default
    $('#new-sdr-dispute').dropdown('toggle')

  $('#new-sdr-dispute-form').submit (e) ->
    e.preventDefault()
    domain = this.sender.value
    reputation = this.reputation.value
    platform = this.platforms.value
    priority = this.priority.value
    customer = this.customers.value
    details = this.details.value

    domain = domain.trim()
    domain = domain.replace('http://', '')
    domain = domain.replace('https://', '')
    domain - domain.replace(/&/g, '&amp;')

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/sdr/disputes'
      method: 'POST'
      data:
        sender_domain_entry: domain,
        suggested_disposition: reputation,
        customer: customer,
        platform: platform,
        priority: priority,
        description: details
      success: (response) ->
        std_msg_success('Dispute Created.', [], reload: true)
      error: (response) ->
        console.log response
        std_api_error(response, "Dispute was not created.", reload: false)
    )