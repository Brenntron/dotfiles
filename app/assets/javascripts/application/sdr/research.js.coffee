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
    error: (error) ->
      std_msg_error(error.responseText, ['Cannot find Whois data.'])
  )

  applyWhoisData = (data) ->
    Object.keys(data).forEach (key) ->
      if data[key]? && typeof data[key] == 'object'
        applyWhoisData(data[key])
      else
        $("##{key}").text(data[key])
        $("##{key}").removeClass('missing-data')
