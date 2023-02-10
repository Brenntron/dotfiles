namespace 'WebCat.RepLookup', (exports) ->
  exports.whoIsLookups = (ipDomain) ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    selected_rows = $("tr.highlight-second-review.shown")

    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/domain_whois'
      method: 'POST'
      headers: headers
      data: {'lookup': ipDomain}
      success: (response) ->
        console.log 'response:', response
        info = $.parseJSON(response)
        console.log 'info:', info
        if info.error
          notice_html = "<p>Something went wrong: #{info.error}</p>"
          alert(info.error)
        else
          dialog_content = $(formatIanaInfo(info, ipDomain))

          if $("#lookup_content").length
            $('#iana_whois > .dialog-content-wrapper').remove()
            $('#iana_whois').html(dialog_content[0])
            $('#lookup_content').dialog('open')
          else
            lookup_content = "<div id='lookup_content' class='ui-dialog-content ui-widget-content' title='Whois for: #{ipDomain}'>
                                <div id='lookup_tabs'>
                                  <ul class='nav nav-tabs'>
                                    <li class='nav-item active' role='presentation'>
                                      <a href='#iana_whois' data-toggle='tab'>IANA WHOIS</a>
                                    </li>
                                    <li class='nav-item' role='presentation'>
                                      <a href='#icann_whois' data-toggle='tab'>ICANN WHOIS</a>
                                    </li>
                                  </ul>
                                </div>
                                <div id='iana_whois' class='tab-pane active' role='tabpanel'></div>
                                <div id='icann_whois' class='tab-pane' role='tabpanel'></div>
                              </div>"
            $('body').append(lookup_content)
            $('#iana_whois').append(dialog_content[0])
            $('#lookup_content').dialog
              autoOpen: true
              classes: {
                'ui-dialog': 'webcat-whois-dialog',
                'ui-dialog-content': 'webcat-whois-dialog-content'
              }
              minWidth: 1000
              position: { my: "right center", at: "right center", of: window }
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
        console.log 'response:', response
        if response != null
          parsedResponse = formatIcannInfo(response.data)
          if $("#lookup_content").length
            $("#icann_whois").html("<div class='dialog-content-wrapper'>#{parsedResponse}</div> ")
            $('#lookup_content').dialog('open')
          else
            lookup_content = "<div id='lookup_content' class='ui-dialog-content ui-widget-content' title='Whois for: #{ipDomain}'>
                                <div id='lookup_tabs'>
                                  <ul class='nav nav-tabs'>
                                    <li class='nav-item active' role='presentation'>
                                      <a href='#iana_whois' data-toggle='tab'>IANA WHOIS</a>
                                    </li>
                                    <li class='nav-item' role='presentation'>
                                      <a href='#icann_whois' data-toggle='tab'>ICANN WHOIS</a>
                                    </li>
                                  </ul>
                                </div>
                                <div id='iana_whois' class='tab-pane active' role='tabpanel'></div>
                                <div id='icann_whois' class='tab-pane' role='tabpanel'></div>
                              </div>"
            $('body').append(lookup_content)
            html = "<div class='dialog-content-wrapper'>#{parsedResponse}</div> "
            $('#icann_whois').append(html)
            $('#lookup_content').dialog
              autoOpen: true
              classes: {
                'ui-dialog': 'webcat-whois-dialog',
                'ui-dialog-content': 'webcat-whois-dialog-content'
              }
              minWidth: 1000
              position: { my: "right center", at: "right center", of: window }
        else
          message = "No available responses. The IP address may be unallocated or its whois server is unavailable."
          $('#lookup_content').append message
      error: (response) ->
        if response != null
          {responseJSON} = response

          console.log response

          if !responseJSON
            std_msg_error("Error retrieving WHOIS query.","")
          else
            std_msg_error("Error retrieving WHOIS query.", [responseJSON.message])

          return $.each(response.responseJSON, (key, value) ->
            console.log value
          )
    )

  formatIanaInfo = (info, ipDomain) ->
    "<div class='dialog-content-wrapper iana-content-wrapper'>
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
    splitData = whoisData.split(/\r?\n/).filter((str) -> str)
    scrapIndex = splitData.findIndex((str) -> str.includes('URL of the ICANN'))
    releventData = splitData.splice(0, scrapIndex).map((s) -> keyify(s)).filter((str) -> str)

  keyify = (s) ->
    kv = s.split(': ')
    if kv[0].trim() == 'Name Server'
      return
    else
      return { "#{kv[0].trim()}": kv[1].trim() }

  stringifyInfo = (parsedInfo) ->
    infoString = ''
    tempDomainStatuses = []

    domainStatusFirstIndex = parsedInfo.findIndex((info) -> info['Domain Status']?)
    domainStatusLastIndex = parsedInfo.findLastIndex((info) -> info['Domain Status']?)
    domainStatusInfo = parsedInfo.slice(domainStatusFirstIndex, domainStatusLastIndex + 1)

    for domainStatus in domainStatusInfo
      tempDomainStatuses.push domainStatus['Domain Status']

    parsedInfo.splice(domainStatusFirstIndex, tempDomainStatuses.length, { "Domain Status": tempDomainStatuses })

    for info in parsedInfo
      if info['Domain Status']?
        domainStatus = '<div class="icann-section row"><h5 class="icann-title col-sm-4">Domain Status</h5><div class="col-sm-8">'

        for dsi in info['Domain Status']
          domainStatus += "<p class='icann-info'>#{dsi}</p>"

        domainStatus += '</div></div>'
        infoString += domainStatus
      else
        infoString += "<div class='icann-section row'><h5 class='icann-title col-sm-4'>#{Object.keys(info)[0]}</h5><p class='icann-info col-sm-8'>#{Object.values(info)[0]}</p></div>"

    infoString
