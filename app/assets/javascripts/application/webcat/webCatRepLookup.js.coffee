namespace 'WebCat.RepLookup', (exports) ->
  exports.whoIsLookups = (ipDomain) ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    selected_rows = $("tr.highlight-second-review.shown")
    $('#ianaLoadingDiv').show()
    $('#icannLoadingDiv').show()

    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/domain_whois'
      method: 'POST'
      headers: headers
      data: {'lookup': ipDomain}
      success: (response) ->
        info = $.parseJSON(response)
        if info.error
          notice_html = "<p>Something went wrong: #{info.error}</p>"
          std_api_error(info.error)
        else
          dialog_content = $(formatIanaInfo(info, ipDomain))

          $('.iana-content-wrapper').remove()
          $('#ianaLoadingDiv').hide()
          $('#iana_whois').append(dialog_content[0])
          $('#lookup_content').dialog
            autoOpen: true
            classes: {
              'ui-dialog': 'webcat-whois-dialog',
              'ui-dialog-content': 'webcat-whois-dialog-content'
            }
            minWidth: 800
            position: { my: "right center", at: "right center", of: window }
            title: "Whois for: #{ipDomain}"
      error: (response) ->
        notice_html = "<p>Something went wrong: #{response.responseText}</p>"
    , this)

    $.ajax(
      method: 'GET'
      url: '/escalations/api/v1/escalations/cloud_intel/whois/lookup'
      headers: headers
      data:
        name: ipDomain
      success: (response) ->
        if response != null
          parsedResponse = formatIcannInfo(response.data)

          $('.icann-content-wrapper').remove()
          $('#icannLoadingDiv').hide()
          $("#icann_whois").append("<div class='icann-content-wrapper'>#{parsedResponse}</div> ")
          $('#lookup_content').dialog
            autoOpen: true
            classes: {
              'ui-dialog': 'webcat-whois-dialog',
              'ui-dialog-content': 'webcat-whois-dialog-content'
            }
            minWidth: 800
            position: { my: "right center", at: "right center", of: window }
            title: "Whois for: #{ipDomain}"
        else
          message = "No available responses. The IP address may be unallocated or its whois server is unavailable."
          $('#lookup_content').append message
      error: (response) ->
        if response != null
          {responseJSON} = response

          if !responseJSON
            std_msg_error("Error retrieving WHOIS query.","")
          else
            std_msg_error("Error retrieving WHOIS query.", [responseJSON.message])

          return $.each(response.responseJSON, (key, value) ->
            console.log value
          )
    )

  formatIanaInfo = (info, ipDomain) ->
    "<div class='iana-content-wrapper'>
      <h5>Domain Name</h5>
      <p>#{ipDomain}</p>
      <h5>Registrant</h5>
      <table class='nested-dialog-table'>
        <tr>
          <td class='table-side-header'>
             Organization
          </td>
          <td>
            #{info['organisation']}
          </td>
        </tr>
        <tr>
          <td class='table-side-header'>
            Country
          </td>
          <td>
            #{info['registrant_country']}
          </td>
        </tr>
        <tr>
          <td class='table-side-header'>
            State/Province
          </td>
          <td>
            #{info['registrant_state/province']}
          </td>
        </tr>
      </table>
      <h5>Name Servers</h5>
      #{name_servers(info['nserver'])}
      <h5> Dates</h5>
      <table class='nested-dialog-table'>
        <tr>
          <td class='table-side-header'>
            Created
          </td>
          <td>#{info['created']}</td>
        </tr><tr>
          <td class='table-side-header'>
            Last updated
          </td>
          <td>
            #{info['changed']}
          </td>
        </tr><tr>
          <td class='table-side-header'>
            Expiry_date
          </td>
          <td>
            #{info['registry_expiry_date']}
          </td>
        </tr>
      </table>
    </div>"

  formatIcannInfo = (whoisData) ->
    parsedInfo = parseIcannInfo(whoisData)
    stringifyedInfo = stringifyInfo(parsedInfo)

  name_servers = (server_list)->
    if undefined == server_list
      ''
    else
      text = ""
      for server in server_list
        text += "<p>#{server}</p>"
      text

  parseIcannInfo = (whoisData) ->
    domainStatuses = []
    nameServers = []
    output = {}

    splitData = whoisData.split(/\r?\n/)
    keyedData = splitData.map((s) -> keyify(s)).filter((str) -> str)

    for data in keyedData
      key = Object.keys(data)[0]
      value = Object.values(data)[0]

      if key == 'Domain Status'
        domainStatuses.push(value)
      else if key == 'Name Server'
        nameServers.push(value)

    reducedData = keyedData.reduce((accumulator, currentValue) ->
      key = Object.keys(currentValue)[0]
      value = Object.values(currentValue)[0]
      accumulator[key] = value
      accumulator
    )

    reducedData['Domain Status'] = domainStatuses
    reducedData['Name Server'] = nameServers
    reducedData['Domain Name'] = reducedData['Domain Name'].toLowerCase()
    return reducedData

  keyify = (s) ->
    unneededKeys = ['URL of the ICANN', 'Last update of', 'NOTICE', 'TERMS OF USE', 'by the following terms of use', 'to']
    kv = s.split(': ')

    if !kv[1]? || (unneededKeys.filter((uk) -> kv[0].includes(uk)).length > 0)
      return
    else
      return { "#{kv[0].trim()}": kv[1].trim() }

  stringifyInfo = (parsedInfo) ->
    domainStatus = '<div class="icann-section row"><h5 class="icann-title col-sm-4">Domain Status</h5><div class="col-sm-8">'
    infoString = ''
    nameServers = '<div class="icann-section row"><h5 class="icann-title col-sm-4">Nameservers</h5><div class="col-sm-8">'
    tempDomainStatuses = []

    for k,v of parsedInfo
      if k == 'Domain Status'
        for ds in v
          domainStatus += "<p class='icann-info'>#{ds}</p>" unless ds.includes('www')
      else if k == 'Name Server'
        for ns in v
          nameServers += "<p class='icann-info'>#{ns.toLowerCase()}</p>"
      else
        infoString += "<div class='icann-section row'><h5 class='icann-title col-sm-4'>#{k}</h5><p class='icann-info col-sm-8'>#{v}</p></div>"

    nameServers += '</div></div>'
    domainStatus += '</div></div>'

    infoString += "#{domainStatus}#{nameServers}"
