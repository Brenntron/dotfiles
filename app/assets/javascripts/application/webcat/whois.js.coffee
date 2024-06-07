namespace 'AC.WebCat.Whois', (exports) ->
  exports.get_whois_data = (ipDomain, success_callback, error_callback) ->
    std_msg_ajax(
      method: 'GET'
      url: '/escalations/api/v1/escalations/cloud_intel/whois/lookup'
      data:
        name: ipDomain
      success: (response) ->
        formattedData = formatIcannData(response.data)
        success_callback(formattedData)
      error: (response) ->
        error_callback(response)
    )

  # The cluster whois dialog doesn't require all the iformation returned by TESS.
  # The inline whois dialog may not need all the information either, and may just
  # need what is displayed for clusters.
  formatIcannData = (whoisData) ->
    parsedData = parseIcannData(whoisData)
    return stringifyData(parsedData)

  parseIcannData = (whoisData) ->
    domainStatuses = []
    keyedData = []
    name_servers = []

    keyedData = whoisData.split(/\r?\n/).map((s) -> keyify(s)).filter((str) -> str)

    console.log('whoisData: ', whoisData)

    for data in keyedData
      key = Object.keys(data)[0].toLowerCase()
      value = Object.values(data)[0]

      if key == 'domain status'
        domainStatuses.push(value)
      else if ['nserver', 'nservers', 'name server'].includes(key)
        name_servers.push(value)

    reducedData = keyedData.reduce((accumulator, currentValue) ->
      key = Object.keys(currentValue)[0].toLowerCase()

      value = Object.values(currentValue)[0]
      accumulator[key] = value
      accumulator
    )

    reducedData['domain status'] = domainStatuses if domainStatuses.length > 0
    reducedData['name servers'] = name_servers
    reducedData['domain name'] = reducedData['name'].toLowerCase() if reducedData['name']?
    reducedData['domain name'] = reducedData['domain name'].toLowerCase() if reducedData['domain name']?
    reducedData['updated'] = reducedData['last-update'] if reducedData['last-update']
    return reducedData

  keyify = (string) ->
    [key, value] = string.split(': ')

    if value? && value.trim()
      return { "#{key.replace(/&quot;/g, '').replace(/&gt;/g, '').trim()}": value.replace(/&lt;/g, '').trim() }

  stringifyData = (parsedData) ->
    dataString = '<table>'
    domainStatus = ''
    name_servers = ''

    for k,v of parsedData
      if k == 'domain status'
        domainStatus = '<h5>Domain Status</h5><table class="nested-dialog-table">'
        for ds in v
          domainStatus += "<tr><td>#{ds}</td></tr>" unless ds.includes('www')
      else if k == 'name servers' && v.length > 0
        name_servers = '<h5>name servers</h5><table class="nested-dialog-table"'
        for ns in v
          name_servers += "<tr><td>#{ns}</td></tr>"
      else if k == 'name_server'
        continue
      else
        dataString += "<tr><th scope='row'>#{k}</th><td>#{v}</td></tr>"

    dataString += '</table>'
    domainStatus += '</table>' if domainStatus.length > 0
    name_servers += '</table>' if name_servers.length > 0

    dataString += "#{domainStatus}#{name_servers}"
