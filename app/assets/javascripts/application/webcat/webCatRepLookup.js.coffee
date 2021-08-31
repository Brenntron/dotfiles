namespace 'WebCat.RepLookup', (exports) ->

  exports.getWhoisLookup = (query_entry) ->

    if sort_column == 'domain'
      sort_column = 'name'

    std_msg_ajax(
      method: 'GET'
      url: '/escalations/api/v1/escalations/cloud_intel/whois/lookup'
      data:
        name: query_entry
      success: (response) ->
        response
      error: (response) ->
        if response != null
          console.log response
          return $.each(response.responseJSON, (key, value) ->
            console.log value
          )
        return
    )

  exports.queryWhoIs = (entry_id, query_entry) ->
    successFunction = (result) ->
      if result != null
        whois = result.data
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
        message = "No available results. The IP address may be unallocated or its whois server is unavailable."
        $('#whois_content').append message

    errorFunction = (response) ->
      {responseJSON} = response
      if !responseJSON
        std_msg_error("Error retrieving WHOIS query.","")
      else
        std_msg_error("Error retrieving WHOIS query.", [responseJSON.message])


    WebCat.RepLookup.getWhoisLookup(query_entry).then successFunction, errorFunction
    return
