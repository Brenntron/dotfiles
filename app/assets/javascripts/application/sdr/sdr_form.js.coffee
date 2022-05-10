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
    $('#new-sdr-dispute').dropdown('toggle')