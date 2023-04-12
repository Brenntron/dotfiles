namespace 'WebCat.RepLookup', (exports) ->
  exports.whoIsLookups = (ipDomain) ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

    if $('#whoisContent').length > 0
      $('#whoisContent').dialog(title: "Whois for: #{ipDomain}").dialog('open')
    else
      whoisContent = "<div id='whoisContent' class='webcat-whois-dialog-content' title='Whois for: #{ipDomain}'>
                        <div class='dialog-content-wrapper'>
                          <div class='lookup_tabs'>
                            <ul class='nav nav-tabs dialog-tabs' role='tablist'>
                              <li class='nav-item active' role='presentation'>
                                <a href='#iana_whois' data-toggle='tab' role='tab'>
                                  IANA WHOIS
                                </a>
                              </li>
                              <li class='nav-item' role='presentation'>
                                <a href='#icann_whois' data-toggle='tab' role='tab'>
                                  ICANN WHOIS
                                </a>
                              </li>
                            </ul>
                          </div>
                          <div id='iana_whois' class='tab-pane active' role='tabpanel'>
                            <div id='inline-webcat' class='webcat-loader-wrapper'>
                              <span class='loader-msg'>
                                Loading Data...
                              </span>
                            </div>
                          </div>
                          <div id='icann_whois' class='tab-pane' role='tabpanel'>
                            <div id='inline-webcat' class='webcat-loader-wrapper'>
                              <span class='loader-msg'>
                                Loading Data...
                              <span>
                            </div>
                          </div>
                        </div>
                      </div>"

      $('body').append(whoisContent)

      $('#whoisContent').dialog
        autoOpen: true
        classes: { 'ui-dialog': 'webcat-whois-dialog' }
        minWidth: 800
        position: { my: "right center", at: "right center", of: window }
        title: "Whois for: #{ipDomain}"

    $('.iana-content-wrapper').remove()
    $('#iana_whois > .webcat-loader-wrapper').show()

    $('#icannContent').remove()
    $('#icann_whois > .webcat-loader-wrapper').show()

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

          $('#iana_whois').append(dialog_content[0])

        $('#iana_whois > .webcat-loader-wrapper').hide()
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

          $("#icann_whois").append("<div id='icannContent'>#{parsedResponse}</div>")
        else
          message = "No available responses. The IP address may be unallocated or its whois server is unavailable."
          $('#whois_content').append message

        $('#icann_whois > .webcat-loader-wrapper').hide()
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
      <hr class='thin'/>
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
      <table>
      #{name_servers(info['nserver'])}
      </table>
      <hr class='thin'/>
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
        text += "<tr><td>#{server}</td></tr>"
      text

  parseIcannInfo = (whoisData) ->
    domainStatuses = []
    nameServers = []
    nservers = []

    splitData = whoisData.split(/\r?\n/)
    keyedData = splitData.map((s) -> keyify(s)).filter((str) -> str)

    for data in keyedData
      key = Object.keys(data)[0]
      value = Object.values(data)[0]

      if key == 'Domain Status'
        domainStatuses.push(value)
      else if key == 'Name Server'
        nameServers.push(value)
      else if key == 'Nserver'
        nservers.push(value)

    reducedData = keyedData.reduce((accumulator, currentValue) ->
      key = Object.keys(currentValue)[0]
      value = Object.values(currentValue)[0]
      accumulator[key] = value
      accumulator
    )

    reducedData['Domain Status'] = domainStatuses if domainStatuses.length > 0
    reducedData['Name Server'] = nameServers if nameServers.length > 0
    reducedData['Nserver'] = nservers if nservers.length > 0
    reducedData['Domain Name'] = reducedData['Domain Name'].toLowerCase() if reducedData['Domain Name']?
    return reducedData

  keyify = (s) ->
    unneededKeys = ['URL of the ICANN', 'Last update of', 'NOTICE', 'TERMS OF USE', 'by the following terms of use', 'to', 'note']
    kv = s.split(': ')

    if !kv[1]? || (unneededKeys.filter((uk) -> kv[0].includes(uk)).length > 0)
      return
    else
      return { "#{kv[0].trim().replace('&quot;', '')}": kv[1].trim() }

  stringifyInfo = (parsedInfo) ->
    infoString = '<table>'
    domainStatus = ''
    nameServers = ''
    nservers = ''

    for k,v of parsedInfo
      if k == 'Domain Status'
        domainStatus = '<h5>Domain Status</h5><table class="nested-dialog-table">'
        for ds in v
          domainStatus += "<tr><td>#{ds}</td></tr>" unless ds.includes('www')
      else if k == 'Name Server'
        nameServers = '<h5>Nameservers</h5><table class="nested-dialog-table">'
        for ns in v
          nameServers += "<tr><td>#{ns.toLowerCase()}</tr></td>"
      else if k == 'Nserver'
        nservers = '<h5>Nservers</h5><table class="nested-dialog-table"'
        for ns in v
          nservers += "<tr><td>#{ns}</td></tr>"
      else
        infoString += "<tr><th scope='row'>#{k}</th><td>#{v}</td></tr>"

    infoString += '</table>'
    domainStatus += '</table>' if domainStatus.length > 0
    nameServers += '</table>' if nameServers.length > 0
    nservers += '</table>' if nservers.length > 0

    infoString += "#{domainStatus}#{nameServers}#{nservers}"
