namespace 'WebCat.RepLookup', (exports) ->
  exports.whoIsLookup = (ipDomain) ->
    headers = {
      'Token': $('input[name="token"]').val(),
      'Xmlrpc-Token': $('input[name="xml_token"]').val()
    }

    if $('#whoisContent').length > 0
      $('#whoisContent').dialog(title: "ICANN Whois for: #{ipDomain}").dialog('open')
    else
      whoisContent = "<div id='whoisContent' class='webcat-whois-dialog-content' title='ICANN Whois for: #{ipDomain}'>
                        <div class='dialog-content-wrapper'>
                          <div id='icann_whois'>
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

    $('#icannContent').remove()
    $('#icann_whois > .webcat-loader-wrapper').show()

    $.ajax(
      method: 'GET'
      url: '/escalations/api/v1/escalations/cloud_intel/whois/lookup'
      headers: headers
      data:
        name: ipDomain
      success: (response) ->
        if response?
          formattedResponse = WebCat.RepLookup.formatIcannData(response.data)

          $("#icann_whois").append("<div id='icannContent'>#{formattedResponse}</div>")
        else
          message = "No available responses. The IP address may be unallocated or its whois server is unavailable."
          $('#whois_content').append message

        $('#icann_whois > .webcat-loader-wrapper').hide()
      error: (response) ->
        if response?
          { responseJSON } = response

          if !responseJSON
            std_msg_error("Error retrieving WHOIS query.","")
          else
            std_msg_error("Error retrieving WHOIS query.", [responseJSON.message])

          return $.each(response.responseJSON, (key, value) ->
            console.log value
          )
    )

  # The cluster whois dialog doesn't require all the iformation returned by TESS.
  # The inline whois dialog may not need all the information either, and may just
  # need what is displayed for clusters.
  exports.formatIcannData = (whoisData) ->
    parsedData = parseIcannData(whoisData)
    return stringifyData(parsedData)

  parseIcannData = (whoisData) ->
    domainStatuses = []
    keyedData = []
    nservers = []

    splitData = whoisData.split(/\r?\n/)

    keyedData = splitData.map((s) -> keyify(s)).filter((str) -> str)

    for data in keyedData
      key = Object.keys(data)[0].toLowerCase()
      value = Object.values(data)[0]

      if key == 'domain status'
        domainStatuses.push(value)
      else if key == 'nserver' || key == 'nservers' || key == 'name server'
        nservers.push(value)

    reducedData = keyedData.reduce((accumulator, currentValue) ->
      key = Object.keys(currentValue)[0].toLowerCase()
      value = Object.values(currentValue)[0]
      accumulator[key] = value
      accumulator
    )

    reducedData['domain status'] = domainStatuses if domainStatuses.length > 0
    reducedData['nserver'] = nservers
    reducedData['domain name'] = reducedData['name'].toLowerCase() if reducedData['name']?
    reducedData['domain name'] = reducedData['domain name'].toLowerCase() if reducedData['domain name']?
    reducedData['updated'] = reducedData['last-update'] if reducedData['last-update']
    return reducedData

  keyify = (s) ->
    # TESS doesn't send the same key/value pairs for every request....
    keys = ['domain name',
            'domain',
            'name',
            'organization name',
            'registrant organization',
            'registrant country',
            'country',
            'registrant state/province',
            'state',
            'province',
            'name servers',
            'nserver',
            'created at',
            'created',
            'update at',
            'last-update',
            'updated date',
            'registry expiry date',
            'expiry date' ]
    kv = s.split(': ')

    if kv[1]? && (keys.filter((k) -> kv[0].toLowerCase().includes(k)).length > 0)
      return { "#{kv[0].trim().replace('&quot;', '')}": kv[1].trim() }

  stringifyData = (parsedData) ->
    dataString = '<table>'
    domainStatus = ''
    nservers = ''

    for k,v of parsedData
      if k == 'domain status'
        domainStatus = '<h5>Domain Status</h5><table class="nested-dialog-table">'
        for ds in v
          domainStatus += "<tr><td>#{ds}</td></tr>" unless ds.includes('www')
      else if k == 'nserver'
        nservers = '<h5>name servers</h5><table class="nested-dialog-table"'
        for ns in v
          nservers += "<tr><td>#{ns}</td></tr>"
      else
        dataString += "<tr><th scope='row'>#{k}</th><td>#{v}</td></tr>"

    dataString += '</table>'
    domainStatus += '</table>' if domainStatus.length > 0
    nservers += '</table>' if nservers.length > 0

    dataString += "#{domainStatus}#{nservers}"

  name_servers = (server_list)->
    if undefined == server_list
      ''
    else
      text = ""
      for server in server_list
        text += "<tr><td>#{server}</td></tr>"
      text
