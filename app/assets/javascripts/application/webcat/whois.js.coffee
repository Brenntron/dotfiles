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
    nservers = []

    splitData = whoisData.split(/\r?\n/)

    keyedData = splitData.map((s) -> keyify(s)).filter((str) -> str)

    for data in keyedData
      key = Object.keys(data)[0].toLowerCase()
      value = Object.values(data)[0]

      if key == 'domain status'
        domainStatuses.push(value)
      else if ['nserver', 'nservers', 'name server'].includes(key)
        nservers.push(value)

    reducedData = keyedData.reduce((accumulator, currentValue) ->
      key = Object.keys(currentValue)[0].toLowerCase()

      return accumulator if key == 'name server'

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
      else if k == 'name servers' && v.length > 0
        nservers = '<h5>name servers</h5><table class="nested-dialog-table"'
        for ns in v
          nservers += "<tr><td>#{ns}</td></tr>"
      else if k == 'nserver'
        continue
      else
        dataString += "<tr><th scope='row'>#{k}</th><td>#{v}</td></tr>"

    dataString += '</table>'
    domainStatus += '</table>' if domainStatus.length > 0
    nservers += '</table>' if nservers.length > 0

    dataString += "#{domainStatus}#{nservers}"
