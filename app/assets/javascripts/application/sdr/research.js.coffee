headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}


window.get_whois_data = (entry) ->
  $.ajax(
    url: '/escalations/api/v1/escalations/cloud_intel/tea/get_data'
    method: 'POST'
    headers: headers
    data: {entry: entry}
    success: (response) ->
      data = response.data
      applyWhoisData(data)
      $('#sdr-research-loader').hide()
      $('.sdr-research-data-present').show()
    error: (error) ->
      std_msg_error(error.responseText, ['Cannot find Whois data.'])
      $('#sdr-research-loader').hide()
      $('.sdr-research-data-missing').show()
  )

  applyWhoisData = (data) ->
    Object.keys(data).forEach (key) ->
      if data[key]? && typeof data[key] == 'object'
        applyWhoisData(data[key])
      else
        $("##{key}").text(data[key])
        $("##{key}").removeClass('missing-data')

  $('#sdr-research-tab .expand-row-button-inline').click ->
    expandButton = $(this)
    nestedRow = expandButton.siblings('.nested-data-row')[0]
    $(nestedRow).toggle()
