namespace 'WebCat.RepLookup', (exports) ->
  exports.whoIsLookups = (queryEntry, ipDomain) ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    selected_rows = $("tr.highlight-second-review.shown")

    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/domain_whois'
      method: 'POST'
      headers: headers
      data: {'lookup': ipDomain}
      success: (response) ->
        info = $.parseJSON(response)
        if info.error
          notice_html = "<p>Something went wrong: #{info.error}</p>"
          alert(info.error)
        else
          dialog_content = $(format_domain_info(info))

          if $("#complaint_button_dialog").length
            complaint_dialog = this

            $('#complaint_button_dialog').html("")
            $('body').innerHTML=""

            $('body').append(complaint_dialog)
            $('#complaint_button_dialog').append(dialog_content[0])
            $('#complaint_button_dialog').dialog
              autoOpen: true
              minWidth: 400
              position: { my: "right bottom", at: "right bottom", of: window }
          else
            complaint_dialog = '<div id="complaint_button_dialog" title="Domain Information"></div>'
            $('body').append(complaint_dialog)
            $('#complaint_button_dialog').append(dialog_content[0])
            $('#complaint_button_dialog').dialog
              autoOpen: true
              minWidth: 400
              position: { my: "right bottom", at: "right bottom", of: window }
      error: (response) ->
        notice_html = "<p>Something went wrong: #{response.responseText}</p>"
    , this)

    $.ajax(
      method: 'GET'
      url: '/escalations/api/v1/escalations/cloud_intel/whois/lookup'
      headers: headers
      data:
        name: queryEntry
      success: (response) ->
        if response != null
          whois = response.data
          if $("#whois_content").length
            $("#whois_content").html("<div class='dialog-content-wrapper'>#{whois}</div> ")
            $('#whois_content').dialog('open')
          else
            whois_content = '<div id="whois_content" class="ui-dialog-content ui-widget-content" title="Lookup Information"></div>'
            $('body').append(whois_content)
            html = "<div class='dialog-content-wrapper'>#{whois}</div> "
            $('#whois_content').append(html)
            $('#whois_content').dialog
              autoOpen: true
              minWidth: 600
              position: { my: "right bottom", at: "right bottom", of: window }
        else
          message = "No available responses. The IP address may be unallocated or its whois server is unavailable."
          $('#whois_content').append message
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

  format_domain_info = (info)->
    '<div class="dialog-content-wrapper">' +
      '<h5>Domain Name</h5>' +
      '<p>' + info['domain'] + '</p>' +
      '<hr class="thin">' +
      '<h5>Registrant </h5>' +
      '<table class="nested-dialog-table">' +
        '<tr>' +
          '<td class="table-side-header">' +
             'Organization' +
          '</td>' +
          '<td>' +
            info['organisation'] +
        '</tr><tr>' +
          '<td class="table-side-header">' +
            'Country' +
          '</td>' +
          '<td>' +
            info['registrant_country'] +
          '</td>' +
        '</tr><tr>' +
          '<td class="table-side-header">' +
          'State/Province' +
          '</td>' +
          '<td>' +
            info['registrant_state/province'] +
          '</td>' +
        '</tr>' +
      '</table>' +
      '<hr class="thin">' +
      '<h5>Name Servers</h5>'+
      name_servers(info['nserver']) +
      '<hr class="thin">' +
      '<h5> Dates</h5>'+
      '<table class="nested-dialog-table">' +
        '<tr>' +
          '<td class="table-side-header">' +
            'Created' +
          '</td>' +
          '<td>' + info['created'] + '</td>'+
        '</tr><tr>' +
          '<td class="table-side-header">' +
            'Last updated' +
          '</td>' +
          '<td>' +
            info['changed'] +
          '</td>' +
        '</tr><tr>' +
          '<td class="table-side-header">' +
            'Expiry_date' +
          '</td>' +
          '<td>' +
            info['registry_expiry_date'] +
          '</td>' +
        '</tr>' +
      '</table>' +
    '</div>'

  name_servers =(server_list)->
    if undefined == server_list
      ''
    else
      text = ""
      for server in server_list
        text += server + '<br>'
      text
