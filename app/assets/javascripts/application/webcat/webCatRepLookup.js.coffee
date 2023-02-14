namespace 'WebCat.RepLookup', (exports) ->
  exports.whoIsLookups = (ipDomain) ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    selected_rows = $("tr.highlight-second-review.shown")
    $('#ianaLoaderDive').show()
    $('#icannLoaderDive').show()

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
          $('#ianaLoaderDive').hide()
          $('#iana_whois').html(dialog_content[0])
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

          $("#icann_whois").html("<div class='icann-content-wrapper'>#{parsedResponse}</div> ")
          $('#icannLoaderDive').hide()
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
    splitData = whoisData.split(/\r?\n/)
    splitData.map((s) -> keyify(s)).filter((str) -> str)

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

    for info in parsedInfo
      if info['Domain Status']?
        dsi = Object.values(info)[0]
        domainStatus += "<p class='icann-info'>#{dsi}</p>" unless dsi.includes('www')
      else if info['Name Server']
        nsi = Object.values(info)[0]
        nameServers += "<p class='icann-info'>#{nsi.toLowerCase()}</p>"
      else
        infoString += "<div class='icann-section row'><h5 class='icann-title col-sm-4'>#{Object.keys(info)[0]}</h5><p class='icann-info col-sm-8'>#{Object.values(info)[0]}</p></div>"

    nameServers += '</div></div>'
    domainStatus += '</div></div>'

    infoString += "#{domainStatus}#{nameServers}"
