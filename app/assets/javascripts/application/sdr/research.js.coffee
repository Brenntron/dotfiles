headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}


window.get_whois_data = (entry) ->
  $.ajax(
    url: '/escalations/api/v1/escalations/cloud_intel/tea/get_data'
    method: 'POST'
    headers: headers
    data: {entry: entry}
    success: (response) ->
      debugger
    error: (error) ->
      std_msg_error(error.responseText, ['Cannot find Whois data.'])
  )
